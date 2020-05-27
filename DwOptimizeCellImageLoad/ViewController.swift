//
//  ViewController.swift
//  DwOptimizeCellImageLoad
//
//  Created by 吴迪玮 on 2020/5/27.
//  Copyright © 2020 davidandty. All rights reserved.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var finalPureLand: CGRect?
    
    let imageUrlStrs = ["http://qiniu.xingheaoyou.com/1.jpg","http://qiniu.xingheaoyou.com/2.jpg","http://qiniu.xingheaoyou.com/3.jpg","http://qiniu.xingheaoyou.com/4.jpg","http://qiniu.xingheaoyou.com/5.jpg","http://qiniu.xingheaoyou.com/6.jpeg","http://qiniu.xingheaoyou.com/7.jpeg","http://qiniu.xingheaoyou.com/8.jpeg"]

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadImageIfNeed()
    }

    @IBAction func cleanCacheAction(_ sender: Any) {
        let cache = KingfisherManager.shared.cache
        cache.clearMemoryCache()
        cache.clearDiskCache()
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10000
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ImageTableViewCell.kReuseIdentifier, for: indexPath) as! ImageTableViewCell
//        cell.loadImage(imageUrlStr: imageUrlStrs[indexPath.row % 8] + "?random=" + randomStrUtil.getRandomStringOfLength(length: 10))
        return cell
    }
}

extension ViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        finalPureLand = nil
        
        loadImageIfNeed()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        finalPureLand = CGRect(x: targetContentOffset.pointee.x, y: targetContentOffset.pointee.y, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
    }
    
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

class ImageTableViewCell: UITableViewCell {
    static let kReuseIdentifier = "ImageTableViewCell"
    
    @IBOutlet weak var avatarImageView: UIImageView!
    let cache = KingfisherManager.shared.cache
    
    override func prepareForReuse() {
        avatarImageView.image = nil
    }
    
    func loadImage(imageUrlStr: String) {
        avatarImageView.kf.setImage(with: URL(string: imageUrlStr))
    }

    func loadImage(imageUrlStr: String, landRect: CGRect?, cellFrame: CGRect) {
        if let landRect = landRect, !landRect.intersects(cellFrame), let image = ImageCache.default.retrieveImageInMemoryCache(forKey: imageUrlStr) {
            // 如果滑动中为减速，则只加载内存中的。
            // 如果加载硬盘中的，硬盘中的加载后要解析转换成位图，也会造成卡顿
            avatarImageView.image = image
        } else {
            loadImage(imageUrlStr: imageUrlStr)
        }
    }
    
//    - (void)lvc_loadVisibleImageWithURL:(NSURL *)imageURL
//                            targetRect:(NSValue *)aTargetRect
//                             cellFrame:(CGRect)aCellFrame {
//
//        // 先判断当前imageView上的图片url 是否与当前要显示的url一致 如果一致的话就不走括号里的处理逻辑 使用当前的图片
//        if (![[self sd_imageURL] isEqual:imageURL]) {
//
//            BOOL shouldLoadImage = YES;
//            SDWebImageManager *manager = [SDWebImageManager sharedManager];
//
//            // self.targetRect是用来判断是否在减速过程当中
//            // !CGRectIntersectsRect([self.targetRect CGRectValue], cellFrame)是用来判断出现的cell是否在目标区域
//            // 4.这两个判断合起来的意思是:tableView正处于减速过程,显示的cell也不在目标区域才为真
//            if (aTargetRect && !CGRectIntersectsRect([aTargetRect CGRectValue], aCellFrame)) {
//
//                SDImageCache *cache = [manager imageCache];
//                NSString *key = [manager cacheKeyForURL:imageURL];
//
//                // 如果不存磁盘 只需要改成imageFromeMemoryCacheForkey:
//                if (![cache imageFromDiskCacheForKey:key]) {
//                    shouldLoadImage = NO;
//                }
//            }
//
//            UIImage *placeholderImage = [UIImage imageNamed:@""];
//            //3. 加载图片
//            if (shouldLoadImage) {
//                [self lad_setImageFadeInWithURL:imageURL placeholderImage:placeholderImage];
//            }else {
//                self.image = placeholderImage;
//            }
//        }
//
//    }
    
}
