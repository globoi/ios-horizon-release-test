# Horizon Client - iOS

O Horizon Client permite acompanhar comportamentos e ações do usuário em seu produto.
Você pode acompanhar quantas páginas seus usuários visitam, quantos vídeos eles assistem,
quantos parágrafos eles lêem ou qualquer ação realizada. Os dados que coletamos podem ser usados como
um guia para recomendação de conteúdo, anúncios e estudos off-line.

The Horizon ecosystem encompasses other projects besides this SDK. The image below illustrates the flow generally used to access the data sent by this SDK. So, before any implementation * we strongly * recommend reading the integration documentation with other projects. The documentation
can be found at this [link](https://tvglobocorp.sharepoint.com/sites/BigDataAI-PlataformaseServios/SitePages/O-Horizon.aspx).

![](images/hoirozn-sdk-data-validation.png)

## Conceitos

**Horizon** é a plataforma atual de métricas de comportamento do usuário. É usado para coletar comportamento,
métricas e interação do usuário entre os produtos da Globo. O sistema é composto
por um biblioteca do lado do cliente chamado `client-android`. O backend é
composto pelo `HorizonTrack`, um *endpoint* HTTP executado no nosso [PaaS Tsuru](https://tsuru.io/), e um *cluster* Kafka.
O principal objetivo do HorizonTrack é ser um gateway HTTP para o cluster Kafka.

Uma mensagem enviada para o servidor passará por um *workload* e será salvo cluster do Hadoop em formato
[parquet](https://parquet.apache.org/). Para saber mais sobre o HorizonTrack por favor visite o seu
[repositório](https://gitlab.globoi.com/bigdata/pipeline/horizon-track-service).

## Arquitetura

O Horizon Client é composto por três componentes principais. O primeiro é o EventBus, responsável
por controlar o envio de eventos gerado pelo usuário para o HorizonTrack. O segundo é validador de schemas,
responsável por garantir a corretude estrutural dos eventos enviados. O último
é SchemasProvider que é responsável por buscar os esquemas suportados pelo Horizon em seu ecossistema.

### Funcionamento do envio de eventos

Para garantir o envio dos eventos independente de conectividade esses são persistidos no armazenamento
interno do dispositivo respeitando o limite máximo de 8 mil eventos. Quando o aplicativo possuir conectividade o envio de eventos é realizado em intervalos
regulares, de forma assincrona, sem utilização de serviços, e somente quando o aplicativo
estiver aberto.

### Schemas

Para melhorar a qualidade dos dados o Horizon Client os valida estruturalmente utilizando
[JSON schemas](http://json-schema.org/), garantindo que todos campos obrigatórios estão preenchidos e
seus tipos estão corretos. Para adicionar novos schemas a plataforma favor seguir as instruções no repositório
de [schemas](https://gitlab.globoi.com/bigdata/pipeline/horizon-schemas).

## Instalando

A biblioteca é distribuida via [CocoaPods](https://cocoapods.org).

Adicione o seguinte `source` e o seguinte `pod` ao seu `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source "https://github.com/globoi/pods-repository"

pod "HorizonClient"
```

## Uso rápido

Aqui temos um guia rápido de como usar o Horizon. Os detalhes são explicados na seção **Passo a Passo**.

```swift
// Na inicialização da aplicação
let horizonEnvironment = (YOUR_APP_ENV) == "prod" ? HorizonEnvironment.prod : HorizonEnvironment.qa
// Caso não haja possibilidade de uso AdvertisingID, o seu valor pode ser nulo.
let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
HorizonClient.useSettings(tenant: "dev-beta", horizonEnvironment: horizonEnvironment, advertisingId: advertisingId)

// Para pegar a instância
let horizonClient = try HorizonClient.get() { error in
    
    if error != nil {
        print("Error:", error!)
    }
    
    print("Is Horizon client ready:", HorizonClient.isReady)
}

// Para enviar um evento
horizonClient.send(schemaId: "generic-click",
                   schemaVersion: "1.0",
                   contentType: "activity",
                   url: "ClickButton",
                   referer: self,
                   properties: ["url": "http://globo.com"]) { event, error in
                       
                       if error != nil {
                            print("Error:", error!)
                            return
                        }
            
                        print("Event Sent:", event)
                   }
```


## Passo a passo

### Configurando o cliente

A configuração do Horizon Client deve ser realizada na inicialização da sua aplicação. O método `HorizonClient.useSettings` recebe dois parâmetros:
- `tenant` O identificador do cliente. Ex: g1, ge, gshow, globoplay...
- `horizonEnvironment` O ambiente para onde o cliente deve enviar os eventos.

```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    /* ... */
    /* your code */
    /* ... */

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Caso não haja possibilidade de uso AdvertisingID, o seu valor pode ser nulo.
        let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        HorizonClient.useSettings(tenant: "dev-beta", horizonEnvironment: horizonEnvironment, advertisingId: advertisingId)
        return true
    }
    /* ... */
    /* your code */
    /* ... */
}
```

### Enviando eventos

Para enviar eventos para o serviço do Horizon, é necessária uma instância de `HorizonClient`. Para isso basta utilizar o método `get()` da classe `HorizonClient` e esperar pelo callback passado como parâmeto para ter certeza que o horizon client foi iniciado com sucesso. O callback passado pode ser omitido caso o cliente ja tenha sido iniciado. Caso o cliente ainda **não tenha sido configurado** na inicialização de sua aplicação uma exceção do tipo `ClientNotConfiguredError` será lançada.

```swift
let horizonClient = try HorizonClient.get() { error in
    
    if error != nil {
        print("Error:", error!)
    }
    
    print("Is Horizon client ready:", HorizonClient.isReady)
}
```

Caso o cliente já tenha sido iniciado com sucesso:
```swift
let horizonClient = try HorizonClient.get()
```

Também é possível checar se o cliente está pronto para uso a qualquer momento pelo método:

```swift
print("Is Horizon client ready? ", HorizonClient.isReady)
```

Com essa instância basta utilizar o método `send` para o envio do evento. Esse método recebe seis parâmetros:
- `schemaId` Identificação do schema.
- `schemaVersion` Versão do schema.
- `contentType` O tipo de conteúdo/componente que gerou esse evento. Ex: multi-content, player.
- `url` Endereço do site ou componente que gerou esse evento. Ex: http://g1.globo.com, UIViewController.
- `referer` Endereço ou componente anterior que levou ao componenete atual.
- `properties` Dados do evento definidos no schema.
- `relationId` Identificador opcional associado ao evento. Recomendamos o uso de [UUID](https://developer.apple.com/
documentation/foundation/uuid).
- `handler` Callback utilizado para notificar quando o evento foi enfileirado com sucesso, ou informando um erro, caso contrário. 

```swift
horizonClient.send(schemaId: "generic-click",
                   schemaVersion: "1.0",
                   contentType: "activity",
                   url: "ClickButton",
                   referer: self,
                   properties: ["url": "http://globo.com"],
                   relationId: "anIdentifier") { event, error in
                        if error != nil {
                            print("Error:", error!)
                            return
                        }
                        
                        print("Queued event:", event.schemaId)
                   }
```

Também é possível enviar uma lista e eventos pelo método `send`:
- `events` uma lista de eventos.
- `realtionId` identificador opcional associado aos eventos. Recomendamos o uso de [UUID](https://developer.apple.com/documentation/foundation/uuid).

O método estático `creatEvent` do `HorizonClient` pode ser utilizado para criar uma lista de eventos.

```swift
let clickEventA = HorizonClient.creatEvent(schemaId: "live-coverage-timeline-view",
        schemaVersion: "1.0",
        contentType: "sad-type",
        url: self,
        referer: self,
        properties: ["coverageId": "12345", "viewTimeMs": 5000])
        
let clickEventB = HorizonClient.creatEvent(schemaId: "live-coverage-timeline-view",
        schemaVersion: "1.0",
        contentType: "sad-type",
        url: self,
        referer: self,
        properties: ["coverageId": "12345", "viewTimeMs": 5000])
        
let relationId = try? HorizonClient
    .get()
    .send(events: [clickEventA, clickEventB], relationId: "anIdentifier") { event, error in

        if error != nil {
            print("Error:", error!)
            return
        }
        
        print("Queued event:", event.schemaId)
    }
```


### Informações sobre usuário anônimo

Para obter o usuário anônimo o cliente disponibiliza o método `getAnonymousUser` que recebe um parâmetro:
- `callbackUser` que deve retornar uma `String, String, String?` onde os parâmetros são:
  - `type` - o tipo do token, no caso do usuário anônimo será `glb_uid`. Caso o valor não esteja disponivel o valor conterá `string vazia`.
  - `value`- o valor do token criptografado. Caso o valor não esteja disponivel o valor conterá `string vazia`.
  - `publicValue` - o valor do token público. Caso o valor não esteja disponivel o valor será `nulo`.

:bangbang: Importante: Os valores que representam o usuário anônimo `SEMPRE` devem ter como fonte esta função. Não é recomendado fazer cache deste valor em hipótese alguma pois o valor pode mudar por regras internas.

```swift
func printAnonymousUser() {
    HorizonClient.getAnonymousUser { type, value, publicValue in
        guard let pubValue = publicValue else {
            print(type, value)
            return
        }

        print(type, value, pubValue)
    }
}
```

Esse callback pode retornar `nil` em situações muito atípicas, mas de qualquer forma esse comportamento deve ser tratado.

### Integração com GloboID SDK

O cliente garante **tracking** de usuário anônimo. Caso queira fazer o **tracking** de usuários logados, o cliente ofereçe suporte ao token `GLBID` provido pela GloboID SDK. A integração pode ser feita de forma simples: basta informar o token `GLBID` na **inicialização** da aplicação e no processo de **login**. É necessário também informar quando o **logout** é efetuado.

#### Inicialização
```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    /* ... */
    /* your code */
    /* ... */

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /* ... */
        /* your code */
        /* ... */

        GloboIDSDK.sharedManager()?.loggedUser { globoUser, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            if let globoUser = globoUser {
                do {
                    try HorizonClient.setLoggedUser(tokenType: .glbid, token: globoUser.glbID)
                } catch {
                    print("Unexpected error: \(error)")
                }
            }
        }
        return true
    }
    /* ... */
    /* your code */
    /* ... */
}
```

#### Login
```swift
func globoUserDidLogin(_ globoUser: GloboUser!) {
    do {
        try HorizonClient.setLoggedUser(tokenType: .glbid, token: globoUser.glbID)
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

#### Logout
```swift
func globoUserDidLogout() {
    do {
        try HorizonClient.removeLoggedUser()
    } catch {
        print("Unexpected error: \(error)")
    }
}
```

#### AdvertisingID Identificador de Propaganda 
Para garantir que todos os eventos sejam enviado associados a um `AdvertisingID` recomendamos a configuração do mesmo nas configurações do Horizon. Um exemplo de uso pode ser encontrado na seção `Configurando o cliente`.

Também é possível adicionar e remover `AdvertisingID` de acordo com a necessidade, basta chamar os os seguintes métodos da SDK:
```swift
    try? HorizonClient.get().setAdvertisingId(advertisingIdentifier: advertisingId)
```
Note que os eventos ainda na fila para serem enviados serão associados ao novo `AdvertisingID`.

Para remover o `AdvertisingID` utilize o código informado abaixo:
```swift
    try? HorizonClient.get().removeAdvertisingId()
```

 Em caso de remoção do `AdvertisingID` tantos os novos eventos quanto os na fila de envio também não serão associados a nenhum `AdvertisingID`.

### Suportando envio de sinais em *background*

Para suportar o envio de sinais quando a aplicação está em *background*, siga os passos abaixo.

- Habilite o modo *Background fetch* nas *Capabilities* do seu projeto.
- Configure o intervalo mínimo de cada envio em *background* chamando o método `setMinimumBackgroundFetchInterval(_:)` da sua `UIApplication`.
- Implemente o método `application(_:performFetchWithCompletionHandler:)` no `UIApplicationDelegate` da aplicação.
- Dentro deste método, chame o método `performFetch(with:)` do `HorizonClient`.

```swift
func performFetch(with completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
```

### Recuperando o hsid

O método abaixo recupera o hsid que é o token de sessão do usuário.

```swift
try? HorizonClient.get().getHsid(callbackHsid: { hsid in
                //hsid recovered for use
                let id = hsid
            })
```



Para mais informações sobre *Background fetch* no iOS, consulte a [documentação da Apple](https://developer.apple.com/documentation/uikit/core_app/managing_your_app_s_life_cycle/preparing_your_app_to_run_in_the_background/updating_your_app_with_background_app_refresh).

## Contato
Globo.com - bigdata.pipeline@corp.globo.com
