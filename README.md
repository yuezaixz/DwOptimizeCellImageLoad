---
title: 优化无限数量快速滑动情况的Cell Image加载过程
date: 2020-05-27 20:49:19
tags:
---

# TableView图片加载优化

## Situation

昨天被位大佬问到当一个TableView有无限多的Cell，当快速滑动时候，如何避免由于加载图片造成的卡顿问题。
UITableView算最常用的UIKit控件之一了，苹果已经为它做了很多优化，比如重用池就解决了反复创建Cell造成的性能问题。
但像iPhone5S上还是无法运行流畅滑动TableView，Cell的离屏渲染、Cell过大、Cell滑动过程大图片加载、业务逻辑阻塞线程等都是造成滑动不流畅的原因。
大图片可以考虑把加载图片的block添加到DefaultRunLoopMode上执行，但大佬说的图片较小，需要滑动过程就立即展现，确实很少会有这种情况，因为一般产品设计和交互设计上，都会有分页加载逻辑，不会出现可以让用户疯狂无限滑动情况。

不过这个问题还是可以研究一下的TableView图片加载优化。

[初始工程分支](https://github.com/yuezaixz/DwOptimizeCellImageLoad/tree/start_project)

### 背景

* 大量图片，url不一致不会被cache命中。
* 快速滑动卡顿或者滑动结束后图片无法加载，因为中间N张图片正在加载，体验糟糕

```

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10000
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageTableViewCell.kReuseIdentifier, for: indexPath) as! ImageTableViewCell
        cell.loadImage(imageUrlStr: imageUrlStrs[indexPath.row % 8] + "?random=" + randomStrUtil.getRandomStringOfLength(length: 10))
        return cell
    }
    
    
}

```

## Task

可以从几个方面去考虑优化：

* 异步渲染，本案例中不使用这个方式，可以使用AsyncDisplayKit(现在叫Texture)
* 根据行为区分加载策略，快速滑动时候，只加载内存缓存的图片，因为磁盘加载还需要解码，生成位图，也是耗时操作；滑动或者减速后才正常通过全缓存和网络进行加载

## Action

### 根据滚动的交互，来控制load

* finalPureLand为放开拖动时候的区域finalPureLand
* 刚刚拖拽时:finalPureLand=nil
* 拖拽完毕的减速过程:速度超过一个常量则finalPureLand=Rect，否则还是nil，finalPureLand有值情况，判断当前界面展现的cell是否在相应范围内，在的话加载内存中图片，没加载到则不加载
* 减速还未完全停止时再次拖拽:finalPureLand=nil
* 手势跟随过程中，仍然加载图片

```

extension ViewController: UIScrollViewDelegate {
    
    // 刚开始拖动，可以加载图片
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        finalPureLand = nil
        
        loadImageIfNeed()
    }
    
    // 滚动过程中，如果手势跟随，加载图片
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isTracking {
            loadImageIfNeed()
        }
    }
    
    // 手势放开，根据速度判断是否要启用内存加载机制
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // 速度低的话，加载，速度快的话，等减速
        // 1 是个magicNum，DEMO项目不要太注意细节 =。。=
        if velocity.y > 1 {
            finalPureLand = CGRect(x: targetContentOffset.pointee.x, y: targetContentOffset.pointee.y, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
        } else {
            finalPureLand = nil
            loadImageIfNeed()
        }
    }
    
    // 结束减速，正常加载图片
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        finalPureLand = nil
        loadImageIfNeed()
    }
    
    func loadImageIfNeed() {
        for cell in tableView.visibleCells {
            if let indexPath = tableView.indexPath(for: cell), let imageCell = cell as? ImageTableViewCell {
                
                // 制造一些可以在内存中展现的cell
                let urlStr = indexPath.row / 10 % 5 == 1 ? imageUrlStrs[indexPath.row % 8] : (imageUrlStrs[indexPath.row % 8] + "?random=\(indexPath.row)")
                let cellRect = tableView.rectForRow(at: indexPath)
                imageCell.loadImage(imageUrlStr: urlStr, landRect: finalPureLand, cellFrame: cellRect)
            }
            
        }
    }
}

```

### 磁盘加载机制

```

func loadImage(imageUrlStr: String, landRect: CGRect?, cellFrame: CGRect) {
        guard !isLoad else { return }
        if let landRect = landRect, !landRect.intersects(cellFrame) {
            // 如果滑动中为减速，则只加载内存中的。
            // 如果加载硬盘中的，硬盘中的加载后要解析转换成位图，也会造成卡顿
            if let image = ImageCache.default.retrieveImageInMemoryCache(forKey: imageUrlStr) {
                isLoad = true
                avatarImageView.image = image
            }
        } else {
            loadImage(imageUrlStr: imageUrlStr)
        }
    }
    
```

## Result

效果上看起来，比start分支的效果和体验好太多了。
本DEMO只是个实例，具体应用还需要进一步优化，并且需要通过TableView和ImageView的扩展或者继承来实现，达到组件复用。

[源码地址](https://github.com/yuezaixz/DwOptimizeCellImageLoad)



