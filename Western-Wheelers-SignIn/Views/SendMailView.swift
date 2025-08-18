import MessageUI
import SwiftUI
import CoreData
import MessageUI

struct SendMailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: MFMailComposeResult?
    @State var messageRecipient: String
    @State var messageSubject: String
    @State var messageContent: String

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var isShowing: Bool
        @Binding var result: MFMailComposeResult?

        init(isShowing: Binding<Bool>,
             result: Binding<MFMailComposeResult?>) {
            _isShowing = isShowing
            _result = result
        }
                
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                isShowing = false
            }
            guard error == nil else {
                self.result = MFMailComposeResult.failed
                return
            }

            self.result = result
            controller.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing, result: $result)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SendMailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setSubject(messageSubject)
        vc.setToRecipients([messageRecipient]) 
        vc.setMessageBody(messageContent, isHTML: true)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<SendMailView>) {

    }
}

