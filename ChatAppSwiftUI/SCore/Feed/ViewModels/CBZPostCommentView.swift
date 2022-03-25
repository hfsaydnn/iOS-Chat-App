//
//  CBZPostCommentView.swift
//  InstagramClone
//
//  Created by Mayil Kannan on 15/04/21.
//

import SwiftUI

struct CBZPostCommentView: View {
    let postComment: CBZPostComment
    var uiConfig: CBZUIConfigurationProtocol

    var body: some View {
        HStack {
            if let commentAuthorProfilePicture = postComment.commentAuthorProfilePicture, !commentAuthorProfilePicture.isEmpty {
                CBZNetworkImage(imageURL: URL(string: commentAuthorProfilePicture)!,
                                placeholderImage: UIImage(named: "empty-avatar")!)
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 25, height: 25)
                    .padding([.leading, .bottom], 4)
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(postComment.commentAuthorUsername ?? "")
                        .font(uiConfig.regularFont(size: 13))
                    Text(postComment.commentText ?? "")
                        .foregroundColor(Color(UIColor.darkGray))
                        .font(uiConfig.regularFont(size: 13))
                        .padding(.top, 2)
                }
                .padding([.leading,.trailing], 15)
                .padding([.top,.bottom], 10)
                Spacer()
            }
            .background(Color(uiConfig.grey1))
            .cornerRadius(12)
            Spacer(minLength: 40)
        }
    }
}
