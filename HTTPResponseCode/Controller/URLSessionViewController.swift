//
//  URLSessionViewController.swift
//  HTTPResponseCode
//
//  Created by Koussaïla Ben Mamar on 11/01/2021.
//

import UIKit

class URLSessionViewController: UIViewController {

    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var responseCodeLabel: UILabel!
    @IBOutlet weak var responseMessageLabel: UILabel!
    @IBOutlet weak var resultMessage: UILabel!
    
    var responseStatus: HTTPResponseStatus?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        responseCodeLabel.isHidden = true
        responseMessageLabel.isHidden = true
        resultMessage.isHidden = true
        
        // Do any additional setup after loading the view.
        urlField.delegate = self
    }
    
    @IBAction func closeViewButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func urlTextFieldSent(_ sender: Any) {
        urlField.resignFirstResponder() // Le clavier disparaît (ce n'est pas automatique de base)
    }
    
    
    @IBAction func testURLbutton(_ sender: Any) {
        let urlText = urlField.text
        urlField.resignFirstResponder() // Le clavier disparaît (ce n'est pas automatique de base)
        resultMessage.isHidden = false
        
        // Champ vide
        guard let urlInput = urlText, !urlInput.isEmpty else {
            resultMessage.text = "Le champ de l'URL est obligatoire."
            urlField.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
            urlField.layer.borderWidth = 1
            
            return
        }
        
        // URL non valide
        guard let url = URL(string: urlText!), url.isFileURL || (url.host != nil && url.scheme != nil) else {
            resultMessage.text = "Le format est invalide."
            urlField.layer.borderColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
            urlField.layer.borderWidth = 1
            
            return
        }
        
        urlField.layer.borderColor = #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1)
        urlField.layer.borderWidth = 1
        responseMessageLabel.isHidden = false
        responseCodeLabel.isHidden = false
        resultMessage.text = "Résultats de la requête HTTP"
        
        // Le "completion handler" est une closure échappée (@escaping), avec la liste de capture [weak self] (weak car self est optionnel) pour éviter la fuite de mémoire
        NetworkService.shared.HTTPRequestURLSession(from: url, completion: { [weak self] responseStatus in
            self?.responseStatus = responseStatus
            print(self?.responseStatus ?? "Pas de réponse")
            
            // Rappel: Mettre à jour l'interface utilisateur doit se faire de façon asynchrone
            DispatchQueue.main.async {
                guard self?.responseStatus != nil else {
                    self?.resultMessage.text = "ERREUR: Pas de réponse."
                    
                    return
                }
                
                if let available = self?.responseStatus?.availableData, available == true {
                    self?.responseMessageLabel.text = "\(self?.responseStatus?.responseMessage ?? "Inconnu")" + ". Données disponibles"
                } else {
                    self?.responseMessageLabel.text = self?.responseStatus?.responseMessage ?? "Inconnu"
                }
                
                self?.responseCodeLabel.text = String(self?.responseStatus?.responseCode ?? 0)
            }
        })
    }
}

// L'utilisateur appuie sur le bouton retour du clavier
extension URLSessionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Le clavier disparaît (ce n'est pas automatique de base)
        return true
    }
}
