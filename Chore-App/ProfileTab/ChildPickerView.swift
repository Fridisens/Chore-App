import SwiftUI

struct ChildPickerView: View {
    @Binding var selectedChild: Child?
    var children: [Child]
    var onAddChild: () -> Void
    
    var body: some View {
        HStack {
            if !children.isEmpty {
                Menu {
                    ForEach(children, id: \.id) { child in
                        Button(action: { selectedChild = child }) {
                            HStack {
                                Image(child.avatar)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .clipShape(Circle())
                                
                                Text(child.name)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        if let selectedChild = selectedChild {
                            Image(selectedChild.avatar)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            
                            Text(selectedChild.name)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        } else {
                            Text("Välj barn")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .frame(minWidth: 140)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                }
                .padding(.trailing, 10)
            } else {
                Text("Inga barn")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
    }
}
