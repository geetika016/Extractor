import UIKit
import MobileCoreServices

class ViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var cameraButton: UIButton!
  
  let processor = ScaledElementProcessor()
  var frameSublayer = CALayer()
  var flaggedIngridientsFound: String = "Non-Compliant Ingridient(s) Found: \n "
  var scannedText: String = "Detected text can be edited here." {
    didSet {
      textView.text = scannedText
    }
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Notifications to slide the keyboard up
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    
    imageView.layer.addSublayer(frameSublayer)
    drawFeatures(in: imageView)
  }
	
  // MARK: Touch handling to dismiss keyboard
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if let evt = event, let tchs = evt.touches(for: view), tchs.count > 0 {
      textView.resignFirstResponder()
    }
  }
  
  // MARK: Actions
  @IBAction func cameraDidTouch(_ sender: UIButton) {
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      presentImagePickerController(withSourceType: .camera)
    } else {
      let alert = UIAlertController(title: "Camera Not Available", message: "A camera is not available. Please try picking an image from the image library instead.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      present(alert, animated: true, completion: nil)
    }
  }
  
  @IBAction func libraryDidTouch(_ sender: UIButton) {
    presentImagePickerController(withSourceType: .photoLibrary)
  }
  
  @IBAction func shareDidTouch(_ sender: UIBarButtonItem) {
    let vc = UIActivityViewController(activityItems: [scannedText, imageView.image!], applicationActivities: [])
    present(vc, animated: true, completion: nil)
  }
  
  // MARK: Keyboard slide up
  @objc func keyboardWillShow(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
      if view.frame.origin.y == 0 {
        view.frame.origin.y -= keyboardSize.height
      }
    }
  }
  
  @objc func keyboardWillHide(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
      if view.frame.origin.y != 0 {
        view.frame.origin.y += keyboardSize.height
      }
    }
  }
  
  private func removeFrames() {
    guard let sublayers = frameSublayer.sublayers else { return }
    for sublayer in sublayers {
      sublayer.removeFromSuperlayer()
    }
  }
  
  
  private func drawFeatures(in imageView: UIImageView, completion: (() -> Void)? = nil) {
    removeFrames()
    self.textView.textColor = UIColor.white
    self.textView.text = "Detecting...."
    flaggedIngridientsFound = "Non-Compliant Ingridient(s) Found: \n "
    processor.process(in: imageView) { text, elements in
      elements.forEach() { elements in
        self.frameSublayer.addSublayer(elements.shapeLayer)
      }
      print("inside viewcontroller process function")
      print(text)
      self.scannedText = text
      let flagIng = ["salt", "starch", "oats"]
      for flags in flagIng
      {
        if(self.scannedText.lowercased().contains(flags))
        {
          self.showSimpleAlert()
          self.flaggedIngridientsFound.append("\n")
          self.flaggedIngridientsFound.append(flags)
        }
      }
      completion?()
    }
  }
}



extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
  // MARK: UIImagePickerController
  
  private func presentImagePickerController(withSourceType sourceType: UIImagePickerController.SourceType) {
    let controller = UIImagePickerController()
    controller.delegate = self
    controller.sourceType = sourceType
    controller.mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
    present(controller, animated: true, completion: nil)
  }
  
  // MARK: UIImagePickerController Delegate
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    if let pickedImage =
      info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
      
      imageView.contentMode = .scaleAspectFit
      let fixedImage = pickedImage.fixOrientation()
      imageView.image = fixedImage
      drawFeatures(in: imageView)
    }
    dismiss(animated: true, completion: nil)
  }
  
  
  func showSimpleAlert() {
    let alert = UIAlertController(title: "Warning!!", message: "Non-Compliant Ingridients Present!",         preferredStyle: UIAlertController.Style.alert)

    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { _ in
          //Cancel Action
      }))
      alert.addAction(UIAlertAction(title: "Details",
                                    style: UIAlertAction.Style.default,
                                    handler: self.showFlaggedIngridients
                                      //Sign out action
      ))
      self.present(alert, animated: true, completion: nil)
      print("alert called")
  }
  
  func showFlaggedIngridients(alert: UIAlertAction!)
  {
    textView.textColor = UIColor.red
    textView.text = flaggedIngridientsFound
  }
}
