//
//  CBZEditStoryViewModel.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 17/06/21.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class CBZEditStoryViewModel: ObservableObject {
    @Published var showLoader: Bool = false

    func saveStories(loggedInUser: ATCUser?, storyComposer: ATCStoryComposerState, completion: @escaping () -> Void) {
        guard let loggedInUser = loggedInUser else { return }

        let db = Firestore.firestore()
        let storiesReference = db.collection("socialnetwork_stories")
        let timestamp = FieldValue.serverTimestamp()
        
        showLoader = true

        var storyDictionary: [String: Any] = [
            "storyType"     :   storyComposer.mediaType ?? "",
            "storyAuthorID" :   loggedInUser.uid ?? "",
            "createdAt"     :   timestamp
        ]

        //Upload Media URL
        if let photo = storyComposer.photoMedia {
            self.uploadImage(photo) { (url) in
                guard let uploadPhotoURL = url else { return }
                let uploadPhotoURLString = uploadPhotoURL.absoluteString
                let newStoryDocument = storiesReference.document()
                storyDictionary["storyMediaURL"] =  uploadPhotoURLString
                storyDictionary["storyID"]  =   newStoryDocument.documentID
                newStoryDocument.setData(storyDictionary)
                self.showLoader = false
                completion()
            }
            return
        } else {
            print("No Photo to Upload")
        }
        
        if let videoURL = storyComposer.videoMedia {
            self.uploadVideo(videoURL) { (url) in
                guard let videoURL = url else { return }
                let videoURLStrng = videoURL.absoluteString
                let newStoryDocument = storiesReference.document()
                storyDictionary["storyMediaURL"] =  videoURLStrng
                storyDictionary["storyID"]  =   newStoryDocument.documentID
                newStoryDocument.setData(storyDictionary)
                self.showLoader = false
                completion()
            }
            return
        }else {
            print("No Video to Upload")
        }
        
    }
    
    private func uploadImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage().reference()
        
        guard let scaledImage = image.scaledToSafeUploadSize, let data = scaledImage.jpegData(compressionQuality: 0.4) else {
            completion(nil)
            return
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let ref = storage.child("SocialNetwork_Posts").child(imageName)
        ref.putData(data, metadata: metadata) { meta, error in
            ref.downloadURL { (url, error) in
                print("Picture URL is : \(url)")
                completion(url)
            }
        }
    }
    
    private func uploadVideo(_ videoURL: URL, completion: @escaping (URL?) -> Void) {
        let storage = Storage.storage().reference()
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        let videoName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
        let ref = storage.child("SocialNetwork_Posts").child(videoName)
        
        ref.putFile(from: videoURL, metadata: metadata) { meta, error in
            ref.downloadURL(completion: { (url, error) in
                print("Video URL is: \(url)")
                completion(url)
            })
        }
    }
}
