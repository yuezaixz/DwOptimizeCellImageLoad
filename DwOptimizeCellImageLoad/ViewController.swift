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
    
    let randomStrUtil = RandomString.sharedInstance
    
    let imageUrlStrs = ["http://qiniu.xingheaoyou.com/1.jpg","http://qiniu.xingheaoyou.com/2.jpg","http://qiniu.xingheaoyou.com/3.jpg","http://qiniu.xingheaoyou.com/4.jpg","http://qiniu.xingheaoyou.com/5.jpg","http://qiniu.xingheaoyou.com/6.jpeg","http://qiniu.xingheaoyou.com/7.jpeg","http://qiniu.xingheaoyou.com/8.jpeg"]

    override func viewDidLoad() {
        super.viewDidLoad()
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
        cell.loadImage(imageUrlStr: imageUrlStrs[indexPath.row % 8] + "?random=" + randomStrUtil.getRandomStringOfLength(length: 10))
        return cell
    }
    
    
}

class ImageTableViewCell: UITableViewCell {
    static let kReuseIdentifier = "ImageTableViewCell"
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    func loadImage(imageUrlStr: String) {
        avatarImageView.kf.setImage(with: URL(string: imageUrlStr))
    }
    
}

class RandomString {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    /**
     生成随机字符串,
     
     - parameter length: 生成的字符串的长度
     
     - returns: 随机生成的字符串
     */
    func getRandomStringOfLength(length: Int) -> String {
        var ranStr = ""
        for _ in 0 ..< length {
            let index = Int(arc4random_uniform(UInt32(characters.count)))
            ranStr.append(characters[characters.index(characters.startIndex, offsetBy: index)])
        }
        return ranStr
        
    }
    
    
    private init() {
        
    }
    static let sharedInstance = RandomString()
}
