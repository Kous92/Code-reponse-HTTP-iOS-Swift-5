# Test requête HTTP (GET) iOS (Swift 5)

Dans toute application utilisant des services réseau (streaming, requêtes HTTP,...), les requêtes HTTP sont inévitables pour envoyer et recevoir des données depuis un serveur relié à Internet (authentification, téléchargement de données, envoi de messages, ...). 

Ici, voici donc une mini-application iOS native qui va effectuer un appel réseau en requête HTTP de type GET en fournissant l'URL à tester. **ATTENTION: il faut respecter le format d'URL en commençant par `http://` ou `https://`.** L'application renverra ainsi un code de réponse de serveur (exemple 200), un message et potentiellement si oui ou non des données sont disponibles.

Cette mini-application effectue cet appel réseau de 2 méthodes (1 ViewController dédié par méthode):
- Par la voie originelle d'Apple avec `URLSession`
- Par un framework tiers très utilisé: Alamofire avec `AF.request()`

Concernant l'application:
- Architecture de l'application: **MVC (voire même MVC-N)**. Dans l'idéal, au niveau professionnel, les architectures **MVVM** et **Clean** sont les plus utilisées (il y a aussi **MVP** et **VIPER**), mais sont plus modulaires.
- Version de déploiement: **iOS 14.0**
- Version de Swift: **5.3**
- Version d'Alamofire: **5.4.1**

Le code à disposition est donc un modèle pour le développement de ses propres applications effectuant des appels réseau pour envoyer et récupérer des données.

## Important à savoir

Le code de l'application iOS est structurée de l'architecture (design pattern) la plus simple: MVC-N (Model View Controller - Network)

### Partie modèle (Model)

Le modèle fait office de structure de données, le contrôleur va depuis le réseau fournir les données à l'instance du modèle et intéragir avec l'interface utilisateur pour afficher les données. Ici, on va faire simple avec une structure (étant donné qu'on passe l'objet par valeur, sinon c'est avec une classe si on passe l'objet par référence). Cet objet va donc stocker des données depuis l'appel réseau et les utiliser dans le `ViewController`. 3 attributs:
- `responseCode: Int?`: optionnel car on peut ne pas avoir de code de réponse (cas du timeout, pas de connexion réseau)
- `responseMessage: String?`: optionnel car on peut ne pas avoir de message de réponse (cas du timeout, pas de connexion réseau)
- `availableData: Bool`: `false` par défaut dans le constructeur, indique la présence de données.

```swift
struct HTTPResponseStatus {
    var responseCode: Int?
    var responseMessage: String?
    var availableData: Bool
    
    init() {
        responseCode = nil
        responseMessage = nil
        self.availableData = false
    }
}
```

### Partie réseau (Network)

Pour des raisons d'optimalité, il faut éviter de créer plusieurs instances d'une classe (cela alourdit la mémoire et le processeur de threads) exécutant des requêtes HTTP. Pour cela, il faut utiliser une instance partagée et utiliser la classe sous forme de singleton, un seul thread suffit donc pour cela.
```swift
import Foundation
import Alamofire

class NetworkService {
    // Ici une seule instance (singleton) suffit pour les appels réseau
    static let shared = NetworkService()

    // De ce fait, l'instance partagée va donc utiliser un constructeur privé
    private init() {

    }
}
```

**RAPPEL: L'utilisation d'Alamofire nécessite d'installer son framework. Dans mon cas, je l'ai installé dans mon projet Xcode via CocoaPods.**

Pour une requête HTTP pour récupérer le code et le message de la réponse, on fournit un objet URL depuis un `String` contenant l'URL à tester et on effectue les traitement avec une closure échappée (d'où le terme `@escaping`) pour effectuer le traitement en dehors du scope de la classe `NetworkService`, donc dans le `ViewController`, il s'agit donc d'un "completion handler".
```swift
func HTTPRequest...(from url: URL, completion: @escaping(HTTPResponseStatus?) -> Void) {
}
```

- Avec URLSession: On stocke une tâche d'appel réseau dans `task` puis après la closure où on définit les traitements, l'exécuter avec `task.resume()`. Dans la closure avec les 3 paramètres en sortie de la requête HTTP GET (data, response, error):
1. On vérifie qu'il n'y a pas d'erreur: `guard let error == nil``
2. On instancie un objet `HTTPResponseStatus()`: `var responseStatus = HTTPResponseStatus()`
3. On vérifie s'il y a une réponse: `if let httpResponse = response as? HTTPURLResponse`
4. On récupère le code de réponse et on le stocke dans l'objet instancié: `responseStatus.responseCode = httpResponse.statusCode`
5. On récupère le message de réponse et on le stocke dans l'objet instancié s'il y en a, dans les cas du bloc `switch`
6. On vérifie si des données sont disponibles: `if let data = data`, `data` pouvant être en `String`, `HTML`, `JSON`, `XML`, ... Si des données disponibles: `responseStatus.availableData = true`
7. Faire un appel du "completion handler" afin que le contenu de la closure échapée de l'arguement de la HTTPRequestURLSession soit exécutée.

```swift
func HTTPRequestURLSession(from url: URL, completion: @escaping(HTTPResponseStatus?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard error == nil else {
            print(error ?? "ERREUR")
            return
        }
        
        //
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
```

- Avec Alamofire: On déclenche d'appel HTTP GET avec:
```swift
AF.request(url).response { response in
}
```
1. On instancie un objet `HTTPResponseStatus()`: `var responseStatus = HTTPResponseStatus()`
2. On vérifie le contenu de la réponse depuis 2 cas via `response.result`: `.success`, `.error`
3. Si c'est `success( _)`:
- 1. On vérifie s'il y a une réponse: `guard let httpResponse = response.response`
- 2. On récupère le code de réponse et on le stocke dans l'objet instancié: `responseStatus.responseCode = httpResponse.statusCode`
- 3. On récupère le message de réponse et on le stocke dans l'objet instancié s'il y en a, dans les cas du bloc `switch`
- 4. On vérifie si des données sont disponibles: `if let data = response.value`, `data` pouvant être en `String`, `HTML`, `JSON`, `XML`, ... Si des données disponibles: `responseStatus.availableData = true`
4. Faire un appel du "completion handler" afin que le contenu de la closure échapée de l'arguement de la HTTPRequestURLSession soit exécutée.
```swift
func HTTPRequestAlamofire(from url: URL, completion: @escaping(HTTPResponseStatus?) -> Void) {
    AF.request(url).response { response in
        // debugPrint(response)
        
        var responseStatus = HTTPResponseStatus()
        
        switch response.result {
            case .success( _):
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
                        
            case .failure(let error):
                print("Error Code: \(error._code)")
                print("Error Messsage: \(error.localizedDescription)")
        }
        
        // La closure échappée faisant office de completion handler sera exécutée dans le second argument depuis le ViewController
        completion(responseStatus)
    }
}
```


### Partie contrôleur (Controller)

Ici, les `ViewController` sont identiques, une pour URLSession, une pour Alamofire. La seule différence sera à l'appel de la fonction réseau.

Lorsque l'utilisateur clique sur le bouton, il est indispensable de vérifier que l'entrée fournie soit une URL, si c'est le cas, on instancie un objet URL.
```swift
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
}
```

C'est alors qu'on fait appel à l'instance partagée de `NetworkService` où on va fournir l'objet url créé précédemment et gérer les traitements dans la closure du "completion handler". **TRÈS IMPORTANT: ON ÉVITE LA RÉTENTION MÉMOIRE AVEC LA LISTE DE CAPTURE DE RÉFÉRENCE FAIBLE `[weak self]`**. De plus, les traitements sur l'interface utilisateur doivent se faire sur le thread principal, donc de façon asynchrone dans la closure `DispatchQueue.main.async` (cela permet aussi d'avoir l'application réactive lors de l'appel réseau).
```swift
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
```

Je vous laisse découvrir le reste dans le code source. Vous pourrez donc réutiliser le contenu dans vos propres applications.