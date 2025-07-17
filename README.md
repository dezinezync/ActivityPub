
# ActivityPub

A sparse implementation for handling and performing ActivityPub activities for Swift on Server using Vapor. 

------

### Installation 
To use with your Vapor project, add the following as the package dependency:
```
.package(url: "https://github.com/dezinezync/ActivityPub.git", branch: "main")

```

```
dependencies: [
  .product(name: "ActivityPub", package: "ActivityPub")
  ...
]
```

## Usage 

### JSONLD Middleware

For any of your routes where an external server may send a request for an ActivityPub/ActivityStream related content, it's best to use `"application/activity+json; charset=utf-8"` as the `Content-Type` header. 

This is a specific requirement for certain S2S communications when federating. 

There is a convinience `Middleware` included `JSONLDContentTypeMiddleware` for this purpose.

To setup:

```swift
func boot(routes: Vapor.RoutesBuilder) throws {
  let group = routes
    .grouped("posts")
    .grouped(JSONLDContentTypeMiddleware())

  group.get(":postID", "comments.json", use: getPostComments)
}
```

Every request to `/:postID/comments.json` will ensure the correct `Content-Type` header is set. 

### APAuthenticator 

`APAuthenticator` is an `AsyncRequestAuthenticator` for validating incoming requests to your ActivityPub server. All ActivityPub requests contain a signature header which we must validate in order to establish authenticity of the request. 

This involves the following steps:
- Extract and parse the signature header
- Fetch the actor's profile, and its public key
- Validate the signature using the actor's public key

Any of these steps can fail (network error, invalid signature, invalid formatting, etc.), so this utility is designed to exit as early as possible.

Typically, the `/:username/inbox` route should assert this validation, so an example for the same will look as follows: 

```swift
let authGroup = routes
  .grouped(JSONLDContentTypeMiddleware())
  .grouped(APAuthenticator())

authGroup.post(":username", "inbox", use: postUserInbox)
```

### APFederationHost

This is a utility class which provides the basic utilities for perform requests to other servers you wish to federate with. It handles the tasks of signing your request, executing it, for a single or multiple endpoints (think: shared inboxes across multiple servers).

For this, your users (actors) will need to have their own public-private keypair. The `ActivityPubKeyManager` utility class can aid with this, generating keys compliant with the ActivityPub requirements. 

```swift

let keyPair = ActivityPubKeyManager.generateECDSAKeyPair()

actor.pubKey = keyPair.publicKey
actor.privKey = keyPair.privateKey

try await actor.saveToDatabase()

// At a later epoch 

let activity = APActivity(...)

try await apFederation.federate(
  object: activity, 
  to: [...], 
  actorKeyId: "https://example.com/myactor#main-key", 
  actorPrivateKey: actor.privateKey, 
  req
)
```

In the above example, please ensure `https://example.com/myactor` resolves with a valid `APActor` response, which lists the actor's public key. Other servers will query this URL to fetch the actor's public key for validating your requests. 

### Fetching Remote Actors

The `APUtilities` file contains a convinience function to fetch an actor profile from any source. 

```swift
let actor: (any APPublicActor) = try await fetchActorProfile(from actorURL: "https://social.dezinezync.com/@nikhil", using: req) 
```

In the above example, the resulting value will either be an instance of `APActor` or `APMastodonProfile`. While both share a lot of common attributes, they differ slightly, so ensure your inspecting the correct attributes at runtime. 

### Miscellaneous 

- `HTTPMediaType` is extended to include common content-types like `ld+json`, `jrd+json`, and `activity+json`. 
- `Either<L,R>` is included, based on https://github.com/swiftlang/swift/blob/main/stdlib/public/core/EitherSequence.swift
- `APWebFingerProfile` struct should be used when querying a `webfinger` reponse from a server. 

#### Your Server

A few key routes your server should implement so other servers in the network can find information about your setup more easily:

- `/nodeinfo/2.0`: Route resolving standardised metadata about your server. [Ref](https://nodeinfo.diaspora.software)
- `.well-known/nodeinfo`: This route should resolve with the following JSON pointing to `/nodeinfo/2.0`:
```json
{
  "links":
  [
    {
      "rel": "http://nodeinfo.diaspora.software/ns/schema/2.0",
      "href": "https://yourtld.com/nodeinfo/2.0"
    }
  ]
}
```

- `/webfinger`: Route resolving information of the queried user. [Ref](https://webfinger.net/spec/)

- `/hostmeta`: A JRD document which vendors metadata about this specific host. This route is used for querying the `webfinger` for your server.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
  <Link rel="lrdd" template="https://yourtld.com/.well-known/webfinger?resource={uri}"/>
</XRD>
```

- `/shared/inbox`: A shared inbox which other servers can use to notify of activity updates (including edits, and deletions).

#### Core ActivityPub

There is an effort to convert this package into a core ActivityPub implementation such that it can be used for all S2S and C2S Swift based implmentations agnostic of the networking provider/layer. 

This removes the dependency on Vapor. A compatability file should be introduced on your Vapor based projects with something similar to the following:
<details>
<summary>ActivityPub+Extensions.swift</summary>
<pre><code>
import Foundation
import ActivityPub
import Vapor

// MARK: - Response Encoding
protocol APResponseEncodable: AsyncResponseEncodable where Self: Content {
  
}

extension APResponseEncodable {
  public func encodeResponse(for request: Request) async throws -> Response {
    let encoder = try ContentConfiguration.global.requireEncoder(for: .activityJSON)
    var headers = HTTPHeaders()
    var byteBuffer = ByteBuffer()
    
    try encoder.encode(self, to: &byteBuffer, headers: &headers)

    headers.remove(name: .contentType)
    headers.add(name: .contentType, value: "application/activity+json")
    return Response(status: .ok, headers: headers, body: Response.Body(buffer: byteBuffer))
  }
}

// MARK: - Client Response

extension ClientResponse: @retroactive APNetworkingResponse {
 public var contentType: HTTPMediaType {
   self.content.contentType ?? .any
  }
}

// MARK: - Request

extension Request: @retroactive APNetworkingRequest {
  // MARK: Network Requests
  public func get(_ url: any CustomStringConvertible, headers: NIOHTTP1.HTTPHeaders) async throws -> (any ActivityPub.APNetworkingResponse, ByteBuffer?) {
    let uri: URI
    
    if let url = url as? URI {
      uri = url
    }
    else if let url = url as? String {
      uri = URI(string: url)
    }
    else if let url = url as? URL {
      uri = URI(string: url.absoluteString)
    }
    else {
      throw Abort(.internalServerError, reason: "Failed to form URI during GET request in protocol conformance from type: \(url.self)")
    }
    
    let res = try await client.get(uri, headers: headers)
    
    return (res, res.body)
  }
  
  public func post<C>(_ url: any CustomStringConvertible, headers: HTTPHeaders, body: C, contentType: HTTPMediaType) async throws -> (any APNetworkingResponse, ByteBuffer?) where C : Content {
    let uri: URI
    
    if let url = url as? URI {
      uri = url
    }
    else if let url = url as? String {
      uri = URI(string: url)
    }
    else if let url = url as? URL {
      uri = URI(string: url.absoluteString)
    }
    else {
      throw Abort(.internalServerError, reason: "Failed to form URI during GET request in protocol conformance from type: \(url.self)")
    }
    
    let res = try await client.post(uri, headers: headers, beforeSend: { req in
      try req.content.encode(body, as: contentType)
    })
    
    return (res, res.body)
  }
  
  // MARK: Encoding
  public var contentType: HTTPMediaType? {
    self.content.contentType
  }
  
  public func encode<C>(_ content: C, as contentType: HTTPMediaType) throws where C : Content {
    try self.content.encode(content, as: contentType)
  }
  
  // MARK: Attributes
  public var uri: any CustomStringConvertible {
    get {
      self.url
    }
    set(newValue) {
      if let newValue = newValue as? URI {
        self.url = newValue
      }
      else if let newValue = newValue as? String {
        self.url = URI(string: newValue)
      }
      else { }
    }
  }
  
  public var resourceURL: URL? {
    URL(string: self.url.string)
  }
}
</code></pre>
</details> 

#### Contributions

Your contributions for extending the source, documentation, bug fixes, etc. are always welcome. Remember to be kind to the contributors, maintainers, and others who are all trying to make things better, one utf8 character slice at a time ;)

#### License

MIT License. Please see the `LICENSE` file for full details. 

