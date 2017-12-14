
import UIKit
import Firebase

class CameraViewController: UIViewController,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{

    @IBOutlet weak var imgPhoto: UIImageView!
    
    
    
    var storageRef: StorageReference!

    
    func configureStorage() {
        let storageUrl = FirebaseApp.app()?.options.storageBucket
        storageRef = Storage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureStorage()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                imgPhoto.image = selectedImage
        } else {
            print("Something went wrong")
        }
        
        dismiss(animated:true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { _ in })
    }
    
    

    func savePhotoAlert(){
        let ac = UIAlertController(title: "Photo Saved!", message:"Your photo was saved successfully", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    
    }
    
    @IBAction func btnSavePhoto_Tap(_ sender: UIBarButtonItem) {
        
        let imageData = UIImageJPEGRepresentation(imgPhoto.image!, 0.8)
        let compressedJPEGImage = UIImage(data: imageData!)
        UIImageWriteToSavedPhotosAlbum(compressedJPEGImage!, nil, nil, nil)
        
       

        let guid = UUID().uuidString

        
        let imagePath = "\(guid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        self.storageRef.child(imagePath)
            .put(imageData!, metadata: metadata) {  (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error)")
                    return
                }
                
                
                let imageUrl = metadata?.downloadURL()?.absoluteString
                
               
                var ref: FIRDatabaseReference!
                ref = FIRDatabase.database().reference()
                
                let imageNode : [String : String] = ["ImageUrl": imageUrl!]
                
                
                ref.child("Photos").childByAutoId().setValue(imageNode)
                
             
                self.savePhotoAlert()
        }
    }

    @IBAction func btnTakePhoto_TouchUpInside(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera)
        {
            let imgPicker = UIImagePickerController()
            imgPicker.delegate = self
            imgPicker.sourceType = .camera
            imgPicker.allowsEditing = false
       
            self.present(imgPicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnPickPhoto_TouchUpInside(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        {
            let imgPicker = UIImagePickerController()
            imgPicker.delegate = self
            imgPicker.sourceType = .photoLibrary
            imgPicker.allowsEditing = true

            self.present(imgPicker, animated: true, completion: nil)
        }
    }

}
