import SwiftUI

struct SettingsView: View {
    let baby: Baby
    
    var body: some View {
        NavigationStack {
            List {
                // 宝宝信息
                Section {
                    HStack {
                        if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(baby.name)
                                .font(.headline)
                            Text("tap_to_edit_baby_info".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 个性化设置
                Section("personalization_settings".localized) {
                    NavigationLink(destination: ThemeColorSettingView()) {
                        HStack {
                            Image(systemName: "palette.fill")
                                .foregroundColor(.accentColor)
                            Text("theme_color".localized)
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: LanguageSettingView()) {
                        HStack {
                            Image(systemName: "textformat")
                                .foregroundColor(.accentColor)
                            Text("language_setting".localized)
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: ModeSettingView()) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.accentColor)
                            Text("mode_setting".localized)
                            Spacer()
                        }
                    }
                }
                
                // 会员特权
                Section {
                    NavigationLink(destination: MembershipPrivilegesView()) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("membership_privileges".localized)
                            Spacer()
                            Text("free".localized)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 关于
                Section("about".localized) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("about_us".localized)
                            Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("help_and_feedback".localized)
                            Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.accentColor)
                        Text("privacy_policy".localized)
                            Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.accentColor)
                        Text("user_agreement".localized)
                            Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}