import SwiftUI
import PhotosUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [Image]
    @Binding var imageDatas: [Data]
    let allowsMultipleSelection: Bool
    let allowsEditing: Bool
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = allowsMultipleSelection ? 9 : 1
        configuration.preferredAssetRepresentationMode = .automatic
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            var newImages: [Image] = []
            var newImageDatas: [Data] = []
            
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                dispatchGroup.enter()
                
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    defer { dispatchGroup.leave() }
                    
                    guard let self = self, let uiImage = object as? UIImage else {
                        return
                    }
                    
                    if self.parent.allowsEditing {
                        // 直接使用原始图片（编辑功能在BabyCreationView中通过UIImagePickerControllerWrapper实现）
                        newImages.append(Image(uiImage: uiImage))
                        if let data = uiImage.jpegData(compressionQuality: 0.8) {
                            newImageDatas.append(data)
                        }
                    } else {
                        // 直接使用原始图片
                        newImages.append(Image(uiImage: uiImage))
                        if let data = uiImage.jpegData(compressionQuality: 0.8) {
                            newImageDatas.append(data)
                        }
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if !newImages.isEmpty {
                    if self.parent.allowsMultipleSelection {
                        // 多选模式：追加图片
                        self.parent.images.append(contentsOf: newImages)
                        self.parent.imageDatas.append(contentsOf: newImageDatas)
                    } else {
                        // 单选模式：替换图片
                        self.parent.images = newImages
                        self.parent.imageDatas = newImageDatas
                    }
                }
            }
        }
        
        // UIImagePickerControllerDelegate 方法
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            
            let uiImage: UIImage?
            if parent.allowsEditing {
                uiImage = info[.editedImage] as? UIImage
            } else {
                uiImage = info[.originalImage] as? UIImage
            }
            
            if let image = uiImage {
                let newImage = Image(uiImage: image)
                if let data = image.jpegData(compressionQuality: 0.8) {
                    if parent.allowsMultipleSelection {
                        // 多选模式：追加图片
                        parent.images.append(newImage)
                        parent.imageDatas.append(data)
                    } else {
                        // 单选模式：替换图片
                        parent.images = [newImage]
                        parent.imageDatas = [data]
                    }
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// 图片选择器菜单，支持相机和相册
struct ImagePickerMenu: View {
    @Binding var images: [Image]
    @Binding var imageDatas: [Data]
    let allowsMultipleSelection: Bool
    let allowsEditing: Bool
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
                    Label("take_photo".localized, systemImage: "camera")
                }
            }
            
            // 相册选项
            Button(action: {
                sourceType = .photoLibrary
                showImagePicker = true
            }) {
                Label("select_from_album".localized, systemImage: "photo.on.rectangle")
            }
        } label: {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                
                Image(systemName: "photo.fill")
                    .font(.title)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            if sourceType == .camera {
                // 相机使用 UIImagePickerController
                ImagePickerWrapper(
                    images: $images,
                    imageDatas: $imageDatas,
                    sourceType: sourceType,
                    allowsEditing: allowsEditing
                )
            } else {
                // 相册使用 PHPickerViewController 支持多选
                ImagePicker(
                    images: $images,
                    imageDatas: $imageDatas,
                    allowsMultipleSelection: allowsMultipleSelection,
                    allowsEditing: allowsEditing
                )
            }
        }
    }
}

// 图片选择器包装器，支持指定来源类型
struct ImagePickerWrapper: UIViewControllerRepresentable {
    @Binding var images: [Image]
    @Binding var imageDatas: [Data]
    let sourceType: UIImagePickerController.SourceType
    let allowsEditing: Bool
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = allowsEditing
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
            let uiImage: UIImage?
            if parent.allowsEditing {
                uiImage = info[.editedImage] as? UIImage
            } else {
                uiImage = info[.originalImage] as? UIImage
            }
            
            if let image = uiImage {
                let newImage = Image(uiImage: image)
                if let data = image.jpegData(compressionQuality: 0.8) {
                    // ImagePickerWrapper 总是用于单选（相机或单张图片选择），所以直接替换
                    parent.images = [newImage]
                    parent.imageDatas = [data]
                }
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}