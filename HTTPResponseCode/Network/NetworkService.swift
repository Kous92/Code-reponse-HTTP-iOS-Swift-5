//
//  NetworkService.swift
//  HTTPResponseCode
//
//  Created by Koussaïla Ben Mamar on 11/01/2021.
//

import Foundation
import Alamofire

class NetworkService {
    // Ici une seule instance (singleton) suffit pour le monitoring du réseau
    static let shared = NetworkService()
    
    // Le "completion handler" est une closure échappée afin qu'elle soit utilisée en dehors du scope de la classe pour appliquer les modifications sur l'interface utilisateur
    func HTTPRequestURLSession(from url: URL, completion: @escaping(HTTPResponseStatus?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard error == nil else {
                print(error ?? "ERREUR")
                return
            }
            
            var responseStatus = HTTPResponseStatus()
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Code: \(httpResponse.statusCode)")
                responseStatus.responseCode = httpResponse.statusCode
                
                switch httpResponse.statusCode {
                    case (200...299):
                        responseStatus.responseMessage = "Succès"
                    case (300...399):
                        responseStatus.responseMessage = "Redirection"
                    case 400:
                        responseStatus.responseMessage = "Requête invalide"
                    case 401:
                        responseStatus.responseMessage = "Identification requise"
                    case 403:
                        responseStatus.responseMessage = "Accès interdit"
                    case 404:
                        responseStatus.responseMessage = "Aucun résultat (Not found)"
                    case 402, (405...499):
                        responseStatus.responseMessage = "Erreur"
                    case (500...599):
                        responseStatus.responseMessage = "Erreur serveur"
                    default:
                        responseStatus.responseMessage = "Statut inconnu"
                }
            }
            
            // Données disponibles
            if let data = data {
                print(data)
                responseStatus.availableData = true
            } else {
                responseStatus.availableData = false
            }
            
            // La closure échappée faisant office de completion handler sera exécutée dans le second argument depuis le ViewController
            completion(responseStatus)
        }
        task.resume()
    }
    
    // Le "completion handler" est une closure échappée afin qu'elle soit utilisée en dehors du scope de la classe pour appliquer les modifications sur l'interface utilisateur
    func HTTPRequestAlamofire(from url: URL, completion: @escaping(HTTPResponseStatus?) -> Void) {
        AF.request(url).response { response in
            // debugPrint(response)
            
            var responseStatus = HTTPResponseStatus()
            
            switch response.result {
                case.success( _):
                    guard let httpResponse = response.response else {
                        print("ERREUR")
                        return
                    }
                    
                    print(httpResponse.statusCode)
                    responseStatus.responseCode = httpResponse.statusCode
                    
                    switch httpResponse.statusCode {
                        case (200...299):
                            responseStatus.responseMessage = "Succès"
                        case (300...399):
                            responseStatus.responseMessage = "Redirection"
                        case 400:
                            responseStatus.responseMessage = "Requête invalide"
                        case 401:
                            responseStatus.responseMessage = "Identification requise"
                        case 403:
                            responseStatus.responseMessage = "Accès interdit"
                        case 404:
                            responseStatus.responseMessage = "Aucun résultat (Not found)"
                        case 402, (405...499):
                            responseStatus.responseMessage = "Erreur"
                        case (500...599):
                            responseStatus.responseMessage = "Erreur serveur"
                        default:
                            responseStatus.responseMessage = "Statut inconnu"
                    }
                    
                    // Données disponibles
                    if let data = response.value {
                        print(data ?? "Pas de donnnées")
                        responseStatus.availableData = true
                    } else {
                        responseStatus.availableData = false
                    }
                            
                case.failure(let error):
                    print("Error Code: \(error._code)")
                    print("Error Messsage: \(error.localizedDescription)")
            }
            
            // La closure échappée faisant office de completion handler sera exécutée dans le second argument depuis le ViewController
            completion(responseStatus)
        }
    }
}
