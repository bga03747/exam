//
//  SearchController.swift
//  FlickrSearch
//
//  Created by Brian Andaliza on 26/05/2016.
//  Copyright © 2016 BrianAndaliza. All rights reserved.
//

import UIKit

class SearchController: UIViewController, UICollectionViewDataSource, GreedoCollectionViewLayoutDataSource, UICollectionViewDelegate, SKPhotoBrowserDelegate, UITextFieldDelegate{
    
    
    private final let screenBound = UIScreen.mainScreen().bounds
    private var screenWidth: CGFloat { return screenBound.size.width }
    private var screenHeight: CGFloat { return screenBound.size.height }
    
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var searchField : UITextField!
    
    
    var feeds : NSMutableArray!
    var skImages = [SKPhotoProtocol]()
    
    var sizeCalculator : GreedoCollectionViewLayout!
    
    @IBAction func searchBtnTapped()
    {
        self.searchField.resignFirstResponder()
        
        self.setup()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        self.searchBtnTapped()
        
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sizeCalculator = GreedoCollectionViewLayout(collectionView: self.collectionView)
        
        self.sizeCalculator.dataSource       = self
        self.sizeCalculator.rowMaximumHeight = CGRectGetHeight(self.collectionView.bounds) / 3
        self.sizeCalculator.fixedHeight      = false
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.collectionView.backgroundColor = UIColor.whiteColor()
        
        
        let layout = UICollectionViewFlowLayout()
        
        layout.minimumInteritemSpacing = 5.0;
        layout.minimumLineSpacing = 5.0;
        layout.sectionInset = UIEdgeInsetsMake(10.0, 5.0, 5.0, 5.0);
        
        self.collectionView.collectionViewLayout = layout;
    }
    
    func setup() {
        
        if(self.searchField.text?.characters.count == 0)
        {
            let alert : UIAlertController = UIAlertController(title: "Hold On!", message: "Please type a search parameter and try again!", preferredStyle: .Alert)
            
            let cancelBtn : UIAlertAction = UIAlertAction(title: "Okay", style: .Cancel, handler: nil)
            
            alert.addAction(cancelBtn)
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else
        {
            self.toggleActivityAnimation(true)
            
            if let flickrURL = NSURL(string: "https://api.flickr.com/services/feeds/photos_public.gne?tags=\(self.searchField.text!)&tagmode=any&per_page=25&format=json&nojsoncallback=1") {
                
                NSURLSession.sharedSession().dataTaskWithURL(flickrURL, completionHandler: { (data, response, error) in
                    
                    let result = NSString(data: data!, encoding: NSUTF8StringEncoding)?.stringByReplacingOccurrencesOfString("\\'", withString: "'")
                    
                    do{
                        let list : NSDictionary = try NSJSONSerialization.JSONObjectWithData((result?.dataUsingEncoding(NSUTF8StringEncoding))!, options: NSJSONReadingOptions.MutableLeaves) as! NSDictionary
                        
                        let items = list.valueForKey("items") as! NSArray
                        var search_results = [SKPhotoProtocol]()
                        
                        
                        for item in items
                        {
                            let dictItem = item as! NSDictionary
                            
                            let mediaDict = dictItem.valueForKey("media") as! NSDictionary
                            let imageURL  = NSURL(string: mediaDict.valueForKey("m") as! String)
                            
                            let imageData = NSData(contentsOfURL: imageURL!)
                            
                            let photo = SKPhoto.photoWithImage(UIImage(data: imageData!)!)
                            photo.caption = dictItem.valueForKey("title") as! String
                            
                            photo.shouldCachePhotoURLImage = true
                            search_results.append(photo)
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            self.skImages = search_results
                            
                            self.toggleActivityAnimation(false)
                            
                            self.collectionView.reloadData()
                        })
                    }
                    catch{
                        
                        self.toggleActivityAnimation(false)
                        
                        print(error)
                    }
                    
                    
                }).resume()
                
            }

        }
        
    }
    
    func toggleActivityAnimation(isActivated : Bool)
    {
        if(isActivated == true)
        {
            self.activityIndicator.startAnimating()
        }
        else
        {
            self.activityIndicator.stopAnimating()
        }
    }
    
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCollectionCell", forIndexPath: indexPath) as? ImageCollectionCell else {
            return UICollectionViewCell()
        }
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        
        imageView.image = self.skImages[indexPath.row].underlyingImage
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.skImages.count
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ImageCollectionCell else {
            return
        }
        let imageView = cell.viewWithTag(1) as! UIImageView
        
        guard let originImage = imageView.image else {
            return
        }
        let browser = SKPhotoBrowser(originImage: originImage, photos: self.skImages, animatedFromView: cell)
        browser.initializePageIndex(indexPath.row)
        browser.delegate = self
        browser.statusBarStyle = .LightContent
        browser.bounceAnimation = true
        browser.displayAction = true

        presentViewController(browser, animated: true, completion: {})
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return self.sizeCalculator.sizeForPhotoAtIndexPath(indexPath)
    }
    
    // MARK: - SKPhotoBrowserDelegate
    func didShowPhotoAtIndex(index: Int) {
        collectionView.visibleCells().forEach({$0.hidden = false})
        collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))?.hidden = true
    }
    
    func willDismissAtPageIndex(index: Int) {
        collectionView.visibleCells().forEach({$0.hidden = false})
        collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))?.hidden = true
    }
    
    
    func didDismissAtPageIndex(index: Int) {
        collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))?.hidden = false
    }

    
    func removePhoto(browser: SKPhotoBrowser, index: Int, reload: (() -> Void)) {
        reload()
    }
    
    func viewForPhoto(browser: SKPhotoBrowser, index: Int) -> UIView? {
        
        return collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0))
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func greedoCollectionViewLayout(layout: GreedoCollectionViewLayout!, originalImageSizeAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        if (indexPath.item < self.skImages.count)
        {
            let searchImage = self.skImages[indexPath.row].underlyingImage as UIImage
            
            return searchImage.size
        }
        
        return CGSizeMake(0.1, 0.1)
    }


}
