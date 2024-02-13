//
//  MailComposeViewController.swift
//  RLYSTATE_v1
//
//  Created by Shervin Mobasheri on 2/13/24.
//

import SwiftUI
import UIKit
import MessageUI

struct MailComposeViewController: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var subject: String
    var recipients: [String]
    var messageBody: String
    var isHTML: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.mailComposeDelegate = context.coordinator
        mailComposeViewController.setSubject(subject)
        mailComposeViewController.setToRecipients(recipients)
        mailComposeViewController.setMessageBody(messageBody, isHTML: isHTML)
        return mailComposeViewController
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeViewController

        init(_ mailComposeViewController: MailComposeViewController) {
            self.parent = mailComposeViewController
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
