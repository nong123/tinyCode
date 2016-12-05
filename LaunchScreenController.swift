//
//  LaunchScreenController.swift
//  GiftTalk-Swift
//
//  Created by Deville on 16/2/23.
//  Copyright © 2016年 liwushuo. All rights reserved.
//

import Foundation
import UIKit
import AlamofireImage

class LaunchScreenController:UIViewController {
    
    let useIdentifierController:SelectIdentityViewController? = nil
    let splashController:SplashController? = nil
    let walkthroughController:WalkthroughController? = nil
    var url:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewSize = UIScreen.mainScreen().bounds.size
        var launchImageName = ""
        if let infoDict = NSBundle.mainBundle().infoDictionary {
            //里面有个字典 专门存的是 每张启动图的设置
            if let imagesDict = infoDict["UILaunchImages"] as? Array<Dictionary<String,String>> {
                // UILaunchImageName:启动图真实名称 NSCFString
                // UILaunchImageMinimumOSVersion:最低适用版本 NSTaggedPointerString
                // UILaunchImageOrientation:横竖屏 Portrait(竖屏) Landscape(横屏) NSTaggedPointerString
                // UILaunchImageSize:图片尺寸 NSCFString
                for dict in imagesDict {
                    if let sizeString = dict["UILaunchImageSize"] {
                        let size = CGSizeFromString(sizeString)
                        if CGSizeEqualToSize(size, viewSize) {
                            launchImageName = dict["UILaunchImageName"] ?? ""
                        }
                    }
                }
            }
        }
        
        let imageView = UIImageView(image: UIImage(named: launchImageName))
        view.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("notificationEvent:"),
            name: "showNextUI",
            object: nil
        )
        
        if OnlineParamManager.instance.updated {
            displayMainView()
        } else {
            NSNotificationCenter.defaultCenter().addObserver(self,
                selector: Selector("displayMainView"),
                name: ConstantNotification.OnlineParamsUpdatedNotification.rawValue,
                object: nil)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        super.viewDidDisappear(animated)
    }
    
    //展示选择身份、launchScreen、splash等view
    func displayMainView() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let _ = userDefaults.valueForKey("gender") {
            let oldVersion = userDefaults.valueForKey("oldVersion") as? String
            if oldVersion != DeviceInfo().buildNum {
                createWalkthrough()
            } else {
                createSplash()
            }
        } else {
            let oldVersion = userDefaults.valueForKey("oldVersion") as? String
            
            if OnlineParams.ShowSelectIdentityView.boolValue() {
                createUserIdentifier()
            } else{
                let request = UsersRequest.userTypeRequest(generation: "3", gender: GenderType.Female)
                request.request({ (res) -> Void in
    
                })
                
                NSUserDefaults.standardUserDefaults().setObject(
                    GenderType.Female,
                    forKey: "gender"
                )
                
                NSUserDefaults.standardUserDefaults().setObject(
                    "3",
                    forKey: "generation"
                )
            }
            if oldVersion != DeviceInfo().buildNum {
                createWalkthrough()
            }
        }
    }
    
    func notificationEvent(notification:NSNotification){
        if let userInfo = notification.userInfo {
            url = userInfo["url"] as? String
        }
        if let vc = notification.object as? UIViewController {
            if childViewControllers.count > 1 {
                vc.view.removeFromSuperview()
                vc.removeFromParentViewController()
            } else {
                changeRootViewController()
            }
        }
    }
    
    /**
     切换 root view controller
     */
    func changeRootViewController() {
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            let rootVC = delegate.rootViewController()
            if let routeURL = url,tabbarVC = rootVC as? TabbarController {
                tabbarVC.routeURL = routeURL
            }
            delegate.window?.rootViewController = rootVC
        }
    }
    
    /**
     选择用户类型
     */
    func createUserIdentifier(){
        let vc = SelectIdentityViewController()
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.view.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    
    /**
     新手引导
     */
    func createWalkthrough(){
        let vc = WalkthroughController()
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.view.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    /**
     广告
     */
    func createSplash(){
        let vc = SplashController()
        addChildViewController(vc)
        view.addSubview(vc.view)
        vc.view.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
}
/// 闪屏广告
class SplashController:UIViewController {
    var imageView = UIImageView()
    var splashModel:SplashModel? = nil
    var skipBtn = UIButton()
    var downloader = ImageDownloader()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
        imageView.contentMode = .ScaleAspectFill
        downloadSplashImage()
    }
    
    func downloadSplashImage(){
        let request = SplashesRequest.SplashImageRequest()
        request.timeoutInterval = 3
        request.request { [weak self] res in
            if let splashModel = res.transformToObject() ,let strongSelf = self{
                strongSelf.splashModel = splashModel
                guard let splashURL = splashModel.splashURL else {
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        "showNextUI",
                        object: self)
                    return }
                guard let imageURL = NSURL(string: splashURL) else {
                    NSNotificationCenter.defaultCenter().postNotificationName(
                        "showNextUI",
                        object: self)
                    return }
                strongSelf.downloadImage(imageURL , model:splashModel)
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "showNextUI",
                    object: self)
            }
        }
    }
    
    func downloadImage(imageUrl:NSURL ,model:SplashModel) {
        let URLRequest = NSURLRequest(URL: imageUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 3)
        downloader.downloadImage(URLRequest: URLRequest) { [weak self] response in
            if let image = response.result.value ,let strongSelf = self{
                strongSelf.showSplashImage(
                    image,
                    duration: model.duration,
                    targetURL: model.url
                )
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(
                    "showNextUI",
                    object: self)
            }
        }
    }
    
    func showSplashImage(image:UIImage , duration:Int , targetURL:String?) {
        self.imageView.image = image
        addButtons()
        NSTimer.scheduledTimerWithTimeInterval(
            1,
            target: self,
            selector: Selector("timerEvent:"),
            userInfo: nil,
            repeats: true)
    }
    
    func addButtons(){
        let goToButton = UIButton(type: .Custom)
        goToButton.frame = imageView.frame
        goToButton.addTarget(
            self,
            action: Selector("goToBtnEvent"),
            forControlEvents: .TouchUpInside)
        view.insertSubview(goToButton, aboveSubview: imageView)
        
        let skipBtn = UIButton(type: .Custom)
        skipBtn.backgroundColor = Color.SkipButtonColor.colorWithAlphaComponent(0.5)
        skipBtn.layer.cornerRadius = 10
        skipBtn.titleLabel?.font = UIFont.defaultFont(11)
        self.skipBtn = skipBtn
        view.addSubview(skipBtn)
        updateSkipBtnTitle()
        skipBtn.addTarget(
            self,
            action: Selector("showNextUI"),
            forControlEvents: .TouchUpInside
        )
        skipBtn.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view).offset(35)
            make.right.equalTo(view).offset(-13)
            make.size.equalTo(CGSizeMake(52, 31))
        }
    }
    
    func timerEvent(sender:NSTimer){
        self.splashModel?.duration--
        if self.splashModel?.duration == 0 {
            sender.invalidate()
            showNextUI()
        }
        updateSkipBtnTitle()
    }
    
    func updateSkipBtnTitle(){
        if let duration = splashModel?.duration {
            skipBtn.setTitle(
                String(format: "%d跳过", duration),
                forState: .Normal)
        }

    }
    
    func goToBtnEvent(){
        if let url = splashModel?.url {
            NSNotificationCenter.defaultCenter().postNotificationName(
                "showNextUI",
                object: self,
                userInfo: ["url":url])
        } else {
            showNextUI()
        }
    }
    func showNextUI(){
        NSNotificationCenter.defaultCenter().postNotificationName(
            "showNextUI",
            object: self)
    }
    
}
/// 新手引导图
class WalkthroughController:UIViewController,UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let doneBtn = UIButton(type: .Custom)
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        let imageArr = makeWalkthroughArr()
        let width:CGFloat = CGRectGetWidth(view.frame)
        scrollView.contentSize = CGSizeMake(width * (CGFloat)(imageArr.count), CGRectGetHeight(view.frame))
        for (i , image) in imageArr.enumerate() {
            let imageView = UIImageView(frame: CGRectMake(width * (CGFloat)(i), 0, width, CGRectGetHeight(view.frame)))
            imageView.image = image
            self.scrollView.addSubview(imageView)
            if i == imageArr.count - 1 {
                let button = UIButton(type: .Custom)
                button.addTarget(self, action: Selector("buttonEvent"), forControlEvents: .TouchUpInside)
                scrollView.addSubview(button)
                button.frame = imageView.frame
            }
        }
        
    }
    
    func buttonEvent() {
        NSUserDefaults.standardUserDefaults().setValue(DeviceInfo().buildNum, forKey: "oldVersion")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        //当不展示用户身份选择页面时，此时若加动画效果会露出底层的imageview
        if self.parentViewController?.childViewControllers.count <= 1 {
            NSNotificationCenter.defaultCenter().postNotificationName(
                "showNextUI",
                object: self)
        }else {
            UIView.animateWithDuration(0.6, animations: { [weak self] in
                if let strongSelf = self {
                    strongSelf.scrollView.alpha = 0
                    strongSelf.scrollView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
                } }) { finished in
                    if finished {
                        NSNotificationCenter.defaultCenter().postNotificationName(
                            "showNextUI",
                            object: self)
                    }
            }

        }
    }
    
    func setupSubviews(){
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.pagingEnabled = true
        view.addSubview(scrollView)
        scrollView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    
    func makeWalkthroughArr() -> Array<UIImage> {
        var arr = [UIImage]()
        var i = 1
        while let image = UIImage(named: String(format: "walkthrough_%d.jpg", i)) {
            i++
            arr.append(image)
        }
        return arr
    }
    

}