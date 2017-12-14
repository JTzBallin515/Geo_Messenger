
import UIKit
import Firebase

class TablesTableViewController: UITableViewController {

    var items: [UserItem] = []
    var ref: DatabaseReference! = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

         self.clearsSelectionOnViewWillAppear = false

    }
    
    func loadDataFromFirebase()
    {
       
        ref.child("MyUsers").observe(.value, with: { snapshot in
           
            var newItems: [UserItem] = []
            
            
            for dbItem in snapshot.children.allObjects {
                let gItem = (snapshot: dbItem )
                
                
                
                let newValue = UserItem(snapshot: gItem as! DataSnapshot)
                newItems.append(newValue)
            }
            
        
            self.items = newItems.sorted{$0.lastName < $1.lastName}
            self.tableView.reloadData()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
  
        self.tableView.contentInset = UIEdgeInsets(top: 40,left: 0,bottom: 0,right: 0)
        
        loadDataFromFirebase()
    }

   
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        let userItem = items[indexPath.row]
        
        cell.textLabel?.text = userItem.firstName
        cell.detailTextLabel?.text = userItem.lastName
        
        toggleCellCheckbox(cell, isCompleted: userItem.isApproved)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        var userItem = items[indexPath.row]
        let toggledCompletion = !userItem.isApproved
        
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        userItem.isApproved = toggledCompletion
        tableView.reloadData()
    }
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.textColor = UIColor.gray
        }
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
       
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let pk = items[indexPath.row].key
            ref.child("MyUsers").child(pk).removeValue()
            
            
            items.remove(at: indexPath.row)
            tableView.reloadData()
            
        } else if editingStyle == .insert {
           
        }    
    }
}
