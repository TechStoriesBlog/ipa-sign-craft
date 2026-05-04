//
//  FileDropView.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 17/03/26.
//

import SwiftUI
internal import UniformTypeIdentifiers

struct FileDropView: View {
    let title: String?
    @Binding var filePath: String
    @State private var isHovering = false
    let supportedTypes: [UTType]

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            // Title
            if let title {
                Text(title)
                    .font(.headline)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.2, dash: [6])
                    )
                    .foregroundColor(
                        isHovering ? Color.blue.opacity(0.6) : Color.gray.opacity(0.4)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )

                VStack(spacing: 6) {

                    Image(systemName: "tray.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    if filePath.isEmpty {
                        Text("Drop IPA file here")
                            .fontWeight(.medium)

                        Text("or click to browse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("IPA package loaded successfully")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 18)
            }
            .onTapGesture {
                // optional: trigger file picker
            }
            .onDrop(of: ["public.file-url"], isTargeted: $isHovering) { providers in

                providers.first?.loadItem(forTypeIdentifier: "public.file-url",
                                         options: nil) { data, _ in
                    DispatchQueue.main.async {

                        if let data = data as? Data,
                           let url = URL(dataRepresentation: data,
                                         relativeTo: nil) {

                            filePath = url.path
                        }
                    }
                }

                return true
            }

            // File picker button (clean separation)
            HStack {
                Spacer()
                FilePickerView(
                    title: "Browse",
                    supportedTypes: supportedTypes,
                    filePath: $filePath
                )
            }
        }
    }
}

#Preview {
    FileDropView(
        title: "FileDropView",
        filePath: .constant("/path/to/file.ipa"),
        supportedTypes: [.ipa]
    )
}
