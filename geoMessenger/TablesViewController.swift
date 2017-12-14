
import UIKit
import Firebase

class TablesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    @IBOutlet weak var txtLastname: UITextField!

    @IBOutlet weak var txtFirstname: UITextField!
    
    @IBAction func btnAddUser(_ sender: CustomButton) {
        
        var ref: DatabaseReference!
        
        ref = Database.database().reference()
        
        let userTable : [String : Any] =
            ["FirstName": txtFirstname.text!,
             "LastName": txtLastname.text!,
             "IsApproved": false]
        
       
        ref.child("MyUsers").childByAutoId().setValue(userTable)
        
    
        let ac = UIAlertController(title: "User Saved!", message:"The user information  was saved successfully!", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        

        txtLastname.text = nil
        txtFirstname.text = nil
    }
}
