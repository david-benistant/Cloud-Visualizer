import SwiftUI

struct AWSRegionPicker: View {
    @StateObject private var viewModel: AWSRegionViewModel = AWSRegionViewModel()
    @Binding var selectedOption: AWSRegionItem

    var body: some View {
        Picker("Region", selection: $selectedOption) {
            ForEach(AWSRegions, id: \.region) { option in
                Text(option.region).tag(option)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onAppear {
            if selectedOption.region == "None" {
                selectedOption = viewModel.loadRegion()
            }

        }
        .onChange(of: selectedOption) {
            if selectedOption.region != "None" {
                viewModel.setCurrent(region: selectedOption)
            }
        }
        .frame(width: 140)
    }
}
