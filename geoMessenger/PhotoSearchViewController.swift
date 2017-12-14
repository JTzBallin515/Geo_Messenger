
import UIKit
import Firebase
import VisualRecognitionV3

class PhotoSearchViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let apiKey = "h35d6203ddcn0d0841b2310dn2376d9644ba8667"
    let version = "2017-09-12"
    let watsonCollectionName = "PhotoCollection"
    var watsonCollectionId = "PhotoCollection"
    
    @IBOutlet weak var btnSearch: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imgPhoto: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var ref: DatabaseReference!
    var existingImageUrls: [ImageUrlItem] = []
    var similarImageUrls: [ImageUrlItem] = []
    var newPhotoRecognitionURL: URL!
    
    @IBAction func btnSearch_Tap(_ sender: UIButton) {
     
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        self.btnSearch.isHidden = true
        
        
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        
     
        let pickPhotoAction = UIAlertAction(title: "Pick from the Gallery", style: .default) { (alert: UIAlertAction!) in
           
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
            {
                let imgPicker = UIImagePickerController()
                imgPicker.delegate = self
                imgPicker.sourceType = .photoLibrary
                imgPicker.allowsEditing = false
               
                self.present(imgPicker, animated: true, completion: nil)
            }
            self.showButton()
        }
        
        //#2
        let takePhotoAction = UIAlertAction(title: "Take a Photo", style: .default) { (alert: UIAlertAction!) in
            if UIImagePickerController.isSourceTypeAvailable(.camera)
            {
                let imgPicker = UIImagePickerController()
                imgPicker.delegate = self
                imgPicker.sourceType = .camera
                imgPicker.allowsEditing = false
                
                self.present(imgPicker, animated: true, completion: nil)
            }
            self.showButton()
        }
        
     
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) in
            
            self.showButton()
        }
        
       
        optionMenu.addAction(pickPhotoAction)
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        
        
    }
    
    func showButton()
    {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()
            self.btnSearch.isHidden = false
        }
    }
    
    func hideButton()
    {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            self.btnSearch.isHidden = true
        }
    }
    
    

    var storageRef: StorageReference!
    
    
    func configureStorage() {
        let storageUrl = FirebaseApp.app()?.options.storageBucket
        storageRef = Storage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    //
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imgPhoto.image = selectedImage
        } else {
            print("Something went wrong")
        }
        
        dismiss(animated:true, completion: nil)
        performSearch()
        
       
    }
    
    func performSearch()
    {
         self.hideButton()
        
      
        let imageData = UIImageJPEGRepresentation(imgPhoto.image!, 0.8)
        let compressedJPEGImage = UIImage(data: imageData!)
        UIImageWriteToSavedPhotosAlbum(compressedJPEGImage!, nil, nil, nil)
        
       
        let guid =  "search_image"
        
        let imagePath = "\(guid)/\(guid).jpg"
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        self.storageRef.child(imagePath)
            .put(imageData!, metadata: metadata) {  (metadata, error) in
                if let error = error {
                    print("Error uploading: \(error)")
                    return
                }
                
        
                self.newPhotoRecognitionURL = URL(string: (metadata?.downloadURL()?.absoluteString)!)!
                self.ref = FIRDatabase.database().reference()
                
              
                self.ref.child("Photos").queryLimited(toLast: 4)
                    .observe(.value, with: { snapshot in
                    
                   
                    for dbItem in snapshot.children.allObjects {
                        let gItem = (snapshot: dbItem )
                        
                     
                        let newValue = ImageUrlItem(snapshot: gItem as! FIRDataSnapshot)
                        self.existingImageUrls.append(newValue)
                    }
                        
                
                    
                 
                    self.visualRecognition = VisualRecognition(apiKey: self.apiKey, version: self.version)
                    

                  
                    self.classifyImage()
                    
                    
                  
                   self.createCollection()
                    
                   
                    for existingImageUrlItem in self.existingImageUrls {
                        
                        print(existingImageUrlItem.imageUrl)
                        self.addCurrentImageToCollection(imageURL: URL(string: existingImageUrlItem.imageUrl)!)
                    }

                    self.findSimilarImages()
                    
         
                   
                        
                        
                
                    print(self.similarImageUrls)

        
                    
                    self.collectionView.reloadData()
                })
        }
         self.showButton()

    }
    
    
    func createCollection()
    {
      
        self.visualRecognition.createCollection(withName: self.watsonCollectionName, success: { (collection) in
            
            self.watsonCollectionId = collection.collectionID
            print("Collection Created")
            print(self.watsonCollectionName)
            print(self.watsonCollectionId)
        })
    }
    
    func removeCollection()
    {
      
        self.visualRecognition.deleteCollection(withID: self.watsonCollectionId)
         print("Collection Removed")
    }
    
    func addCurrentImageToCollection(imageURL: URL)
    {
    
        self.visualRecognition.addImageToCollection(withID: self.watsonCollectionId, imageFile: imageURL) { (colImages) in
        
            print(colImages.collectionImages.count)
        }
    }
    
    
    func findSimilarImages()
    {
        print(newPhotoRecognitionURL! )
        print (self.watsonCollectionId)
        
        self.visualRecognition.findSimilarImages(toImageFile: newPhotoRecognitionURL!,
                                                 inCollectionID: self.watsonCollectionId,
                                                 limit: 9,
        failure: { (searchError) in
            print(searchError)
            self.removeCollection()
        },
        success: { similarImageList in
            
            if let classifiedImage = similarImageList.similarImages.first
            {
                print(classifiedImage.score!)
                
                var counter = 1
            
                for similarImageItem in similarImageList.similarImages {
                        let newValue = ImageUrlItem.init(imageUrl: similarImageItem.imageFile, key: String(counter))
                        self.similarImageUrls.append(newValue)
                        counter += 1
                }
            }
            else
            {
                DispatchQueue.main.async {
                   
                    let ac = UIAlertController(title: "Photo Search Failed!", message:"Your photo search was not successful. Try again later", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
            self.removeCollection()
            
        })
        
        
    }
    
    func classifyImage()
    {
       
        let failure = {(error:Error) in
            DispatchQueue.main.async {
              
                let ac = UIAlertController(title: "Photo Search Failed!", message:"Your photo search was not successful. Try again later", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
            
        
            print(error)
        }
        

        self.visualRecognition.classify(image: (self.newPhotoRecognitionURL?.absoluteString)!, failure: failure){
            classifiedImages in
            
            if let classifiedImage = classifiedImages.images.first
            {
                print(classifiedImage.classifiers)
                
                if let results = classifiedImage.classifiers.first?.classes.first?.classification {
                    
                    DispatchQueue.main.async {
                      
                        self.title = results
                        
                    }
                    
                }
            }
            else
            {
                DispatchQueue.main.async {
                  
                    let ac = UIAlertController(title: "Photo Search Failed!", message:"Your photo search was not successful. Try again later", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: { _ in })
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        activityIndicator.isHidden = true
        configureStorage()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 9
    }
    
    

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "PhotoCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! PhotoCell
        cell.backgroundColor = UIColor(red:0.96, green:0.97, blue:0.99, alpha:1.0)
        
           if similarImageUrls.count > 0 {
                let image = self.similarImageUrls[indexPath.row]
            
    
            let url = URL(string: image.imageUrl)
            
            DispatchQueue.global().async {
            
                DispatchQueue.main.async {
                    cell.imgPhoto.af_setImage(withURL: url!)
                    
                }
            }

        }
        return cell
    }
    
}
