//
//  FileUploadHandler.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 21/03/26.
//

import UIKit
import UniformTypeIdentifiers

class FileUploadHandler: NSObject,
                         UIDocumentPickerDelegate,
                         UIImagePickerControllerDelegate,
                         UINavigationControllerDelegate {

    var completion: (([URL]?) -> Void)?

    func openChooser(from vc: UIViewController,
                     completion: @escaping ([URL]?) -> Void) {

        self.completion = completion

        let alert = UIAlertController(title: "Upload", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            vc.present(picker, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Files", style: .default) { _ in
            let picker = UIDocumentPickerViewController(
                forOpeningContentTypes: [.image, .pdf])
            picker.delegate = self
            picker.allowsMultipleSelection = true
            vc.present(picker, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        vc.present(alert, animated: true)
    }
}
