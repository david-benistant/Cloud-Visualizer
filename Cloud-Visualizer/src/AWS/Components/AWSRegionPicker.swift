import SwiftUI

struct AWSRegionPicker: View {
    @StateObject private var viewModel: AWSRegionViewModel = AWSRegionViewModel()
    @Binding var selectedOption: AWSRegionItem?

    var body: some View {
        Picker("Region", selection: $selectedOption) {
            if selectedOption == nil {
                Text("Select a region").tag(nil as AWSRegionItem?)
            }
            ForEach(AWSRegions, id: \.region) { option in
                Text(option.region).tag(option)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onAppear {
            if selectedOption == nil {
                selectedOption = viewModel.loadRegion()
            }

        }
        .onChange(of: selectedOption) {
            if selectedOption != nil {
                viewModel.setCurrent(region: selectedOption!)
            }
        }
        .frame(width: 140)
    }
}
