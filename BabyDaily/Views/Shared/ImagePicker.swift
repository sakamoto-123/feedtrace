import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: Image?
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage {
                parent.image = Image(uiImage: uiImage)
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// 图片选择器菜单，支持相机和相册
struct ImagePickerMenu: View {
    @Binding var image: Image?
    @Binding var imageData: Data?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        Menu {
            // 相机选项（如果设备支持）
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(action: {
                    sourceType = .camera
                    showImagePicker = true
                }) {
                    Label("拍照", systemImage: "camera")
                }
            }
            
            // 相册选项
            Button(action: {
                sourceType = .photoLibrary
                showImagePicker = true
            }) {
                Label("从相册选择", systemImage: "photo.on.rectangle")
            }
        } label: {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerWrapper(image: $image, imageData: $imageData, sourceType: sourceType)
        }
    }
}

// 图片选择器包装器，支持指定来源类型
struct ImagePickerWrapper: UIViewControllerRepresentable {
    @Binding var image: Image?
    @Binding var imageData: Data?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerWrapper
        
        init(_ parent: ImagePickerWrapper) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.editedImage] as? UIImage {
                parent.image = Image(uiImage: uiImage)
                parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}