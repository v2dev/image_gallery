import Flutter
import UIKit
import Photos

public class SwiftFlutterGallaryPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "image_gallery", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterGallaryPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    
    func getAllImages(completionHandler : @escaping ((_ allImages : [NSDictionary]?) -> Void))
    {
        let imgManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var allImages = [String]()
        //        var allImages = [UIImage]()
        var totalItration = 0
        var allAssetsDict = [NSDictionary]()
        for index in 0..<fetchResult.count
        {
            let assetDetailsDict: NSMutableDictionary = [:]
            let asset = fetchResult.object(at: index) as PHAsset
            imgManager.requestImage(for: asset, targetSize: CGSize(width: 512.0, height: 512.0), contentMode: .aspectFill, options: requestOptions, resultHandler: { (image, info) in
                asset.getURL(completionHandler: { (url, type) in
                    
                    if image != nil {
                        var imageData: Data?
                        if let cgImage = image!.cgImage, cgImage.renderingIntent == .defaultIntent {
                            imageData = UIImageJPEGRepresentation(image!, 0.8)
                        }
                        else {
                            imageData = UIImagePNGRepresentation(image!)
                        }
                        let guid = ProcessInfo.processInfo.globallyUniqueString;
                        let tmpFile = String(format: "image_picker_%@.jpg", guid);
                        let tmpDirectory = NSTemporaryDirectory();
                        let tmpPath = (tmpDirectory as NSString).appendingPathComponent(tmpFile);
                        if(FileManager.default.createFile(atPath: tmpPath, contents: imageData, attributes: [:])) {
                            //                            allImages.append(tmpPath)
                            totalItration += 1
                            allImages.append((url?.path)!)
                            
                            assetDetailsDict.setValue(tmpPath, forKey: "thumbailPath")
                            assetDetailsDict.setValue(type, forKey: "typeOfMedia")
                            assetDetailsDict.setValue(url?.path, forKey: "actulaPath")
                            allAssetsDict.append(assetDetailsDict)
                        }
                    }
                    
                    if totalItration == (fetchResult.count) {
//                                                print(allAssetsDict.count)
//                        completionHandler(allImages)
                        completionHandler(allAssetsDict)
                    }
                })
            })
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "getPlatformVersion") {
            result("iOS " + UIDevice.current.systemVersion)
        }
        else if (call.method == "getAllImages") {
            
            self.getAllImages(completionHandler: { (allImages) in
                result(allImages)
            })
            
        }
    }
}

extension PHAsset {
    
    func getURL(completionHandler : @escaping ((_ responseURL : URL?, _ typeOfMedia : String ) -> Void)){
        if self.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            self.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable : Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL as URL?, "image")
            })
        } else if self.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl: URL = urlAsset.url as URL
                    completionHandler(localVideoUrl, "video")
                } else {
                    completionHandler(nil, "")
                }
            })
        }
    }
}
