

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    var wikipediaURl = "https://en.wikipedia.org/w/api.php"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[.editedImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else { fatalError("Couldn't convert image to CIImage") }
            //imageView.image = userPickedImage
            
            detect(flowerImage: ciImage)
        }
        imagePicker.dismiss(animated: true)
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true)
    }
    
    func detect(flowerImage: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassification().model) else { fatalError("Couldn't load model") }
        let request = VNCoreMLRequest(model: model) { request, error in
            let results = request.results?.first as? VNClassificationObservation
            
            if let topResult = results {
                self.navigationItem.title = topResult.identifier.capitalized
                self.requestInfo(flowerName: topResult.identifier)
            } else {
                self.navigationItem.title = "Unknown Flower"
            }
        }
        let handler = VNImageRequestHandler(ciImage: flowerImage)
        do {
            try handler.perform([request])
        } catch {
            printContent(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize" : "500"
          ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    
                    let pageId = json["query"]["pageids"][0].stringValue
                    
                    let extract = json["query"]["pages"][pageId]["extract"].stringValue
                    
                    let flowerImageUrl = json["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                    
                    self.imageView.sd_setImage(with: URL(string: flowerImageUrl))
                    
                    self.label.text = extract
                    
                case .failure(let error):
                    print(error)
                }
            }
    }
    
}

