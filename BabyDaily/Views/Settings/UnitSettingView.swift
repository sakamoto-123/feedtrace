import SwiftUI

struct UnitSettingView: View {
    @StateObject private var unitManager = UnitManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // 温度单位
                Section {
                   HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text("temperature_unit".localized)
                            .font(.headline)
                        Text("select_temperature_unit".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        Spacer()
                        
                        Picker("Temperature Unit", selection: $unitManager.temperatureUnit) {
                            ForEach(TemperatureUnit.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(.secondary)
                        .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
                
                // 重量单位
                Section {
                  
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("weight_unit".localized)
                                .font(.headline)
                            Text("select_weight_unit".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("Weight Unit", selection: $unitManager.weightUnit) {
                            ForEach(WeightUnit.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                              .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(.secondary)
                        .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
                
                // 长度单位
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("length_unit".localized)
                                .font(.headline)
                            Text("select_length_unit".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("Length Unit", selection: $unitManager.lengthUnit) {
                            ForEach(LengthUnit.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(.secondary)
                        .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
                
                // 体积单位
                Section {
                    HStack{
                        VStack(alignment: .leading, spacing: 4) {
                            Text("volume_unit".localized)
                                .font(.headline)
                            Text("select_volume_unit".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Picker("Volume Unit", selection: $unitManager.volumeUnit) {
                            ForEach(VolumeUnit.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                       .pickerStyle(.menu)
                        .labelsHidden()
                        .tint(.secondary)
                        .frame(maxWidth: 100, alignment: .trailing)
                    }
                    
                }
            }
            .navigationTitle("unit_settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
             .animatedTabBarHidden()
        }
    }
}
