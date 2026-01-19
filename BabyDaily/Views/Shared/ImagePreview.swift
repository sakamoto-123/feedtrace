import SwiftUI

struct ImagePreview: View {
    let images: [Data]
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    init(images: [Data], initialIndex: Int) {
        self.images = images
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // 图片预览区域
                TabView(selection: $currentIndex) {
                    ForEach(images.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: images[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .edgesIgnoringSafeArea(.top)
                
                // 底部控制区域
                VStack {
                    // 图片索引
                    Text("\(currentIndex + 1)/\(images.count)")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.vertical, 8)
                    
                    // 缩略图滚动视图
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(images.indices, id: \.self) { index in
                                    if let uiImage = UIImage(data: images[index]) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(.background, lineWidth: index == currentIndex ? 2 : 0)
                                            )
                                            .opacity(index == currentIndex ? 1.0 : 0.6)
                                            .onTapGesture {
                                                currentIndex = index
                                            }
                                            .id(index)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .onChange(of: currentIndex) {
                            proxy.scrollTo(currentIndex, anchor: .center)
                        }
                    }
                }
                .background(Color.black.opacity(0.8))
            }
            
            // 完成按钮
            Button(action: {
                dismiss()
            }) {
                Text("完成")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .position(x: UIScreen.main.bounds.width - 70, y: 50)
        }
    }
}
