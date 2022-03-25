import SwiftUI
import Photos

struct CBZImagePicker: UIViewControllerRepresentable {
    
    @Binding var isShown: Bool
    @Binding var isShownSheet: Bool
    @State var allMedia: Bool = false
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State var completion:((_ image:UIImage?, _ videoURL: URL?) -> Void)?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        
        @Binding var isShown: Bool
        @Binding var isShownSheet: Bool
        @Binding var allMedia: Bool
        @Binding var completion:((_ image:UIImage?, _ videoURL: URL?) -> Void)?

        init(isShown: Binding<Bool>, isShownSheet: Binding<Bool>, allMedia: Binding<Bool>, completion:Binding<((_ image:UIImage?, _ videoURL: URL?) -> Void)?>) {
            _isShown = isShown
            _isShownSheet = isShownSheet
            _allMedia = allMedia
            _completion = completion
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if !isShown {
                return
            }
            isShown = false
            isShownSheet = false
            if allMedia {
                if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
                    let size = CGSize(width: 500, height: 500)
                    var imageRequestOptions: PHImageRequestOptions {
                        let options = PHImageRequestOptions()
                        options.deliveryMode = .highQualityFormat
                        return options
                    }
                    PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: imageRequestOptions) { result, info in
                        guard let image = result else {
                            return
                        }

                        self.completion?(image, nil)
                    }
                } else if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    completion?(image, nil)
                } else if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == "public.movie" {
                    if let mediaURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL  {
                        
                        let videoData = NSData(contentsOf: mediaURL)
                        let videoFileUrl = documentDirectory().appendingPathComponent("recordingVideo.mp4")
                        
                        do {
                            if FileManager.default.fileExists(atPath: videoFileUrl.path) {
                                try FileManager.default.removeItem(at: videoFileUrl)
                            }
                            videoData?.write(to: videoFileUrl, atomically: false)
                        } catch (let error) {
                            print("Cannot copy: \(error)")
                        }
                        self.completion?(nil, videoFileUrl)
                    }
                }
            } else {
                let imagePicked = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
                completion?(imagePicked, nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            isShown = false
            isShownSheet = false
        }
        
        func documentDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShown: $isShown, isShownSheet: $isShownSheet, allMedia: $allMedia, completion: $completion)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CBZImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        if allMedia {
            picker.mediaTypes = ["public.image", "public.movie"]
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<CBZImagePicker>) {
        
    }
    
}
