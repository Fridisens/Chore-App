import SwiftUI

struct AvatarPicker: View {
    @Binding var selectedAvatar: String
    var onAvatarSelected: () -> Void
    
    let avatars = ["avatar1", "avatar2", "avatar3", "avatar4", "avatar5", "avatar6", "avatar7", "avatar8", "avatar9", "avatar10"]
    
    var body: some View {
        VStack {
            Text("Välj en bild")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(avatars, id: \.self) { avatar in
                        Image(avatar)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(selectedAvatar == avatar ? Color.blue : Color.clear, lineWidth: 3))
                            .onTapGesture {
                                selectedAvatar = avatar
                                onAvatarSelected()
                            }
                    }
                }
            }
        }
    }
}
