import Foundation

/// # Mensajes
/// Se espera que cada línea sea gestionada por...
///
/// * Líneas 1 y 2. Voyager handler
/// * Línea 3. Mensaje desconocido
/// * Lñinea 4. Orion handler
/// * Línea 5. Perseverance handler


let messages = """
VYYR    1   3456123.234 0   0   0   1
VYYR    2   4013225.909 0   0   0   1
---FAKE MESSAGE---FAKE MESSAGE---
{ "message": "Testing para explicar CoR" }
SOL:668TEM:12.5HUM:4.0WND:35.92
"""

enum Mission {
    case perseverance
    case orion
    case voyager
}

enum MessageError: Error {
    case malformed(message: String, mission: Mission)
    case unknown
}

///
/// Mensaje que se espera de la Orion
///

struct OrionMessage: Codable {
    private(set) var message: String
}

///
/// Miembros de la Chain of Responsibility
///

protocol MessageHandler {
    var nextHandler: MessageHandler? { get set }
    
    func process(_ message: String) throws
}

final class PerseveranceMessageHandler: MessageHandler {
    var nextHandler: MessageHandler?
    
    func process(_ message: String) throws {
        let regex = #/^SOL:(?<diaMarciano>\d{1,})TEM:(?<temperatura>\d{1,}\.\d{1,2})HUM:(?<humedad>\d{1,}\.\d{1,2})WND:(?<velocidadViento>\d{1,3}\.\d{1,2})/#
        
        let match = try regex.firstMatch(in: message)
        
        if let match {
            print("🤖 Perseverance. Día \(match.diaMarciano) de misión. \(match.temperatura)º sobre la superficie")
        } else if let nextHandler {
            try nextHandler.process(message)
        } else {
            throw MessageError.unknown
        }
    }
}

final class OrionMessageHandler: MessageHandler {
    var nextHandler: MessageHandler?
    
    func process(_ message: String) throws {
        let jsonDecoder = JSONDecoder()
        
        do {
            guard let data = message.data(using: .utf8) else {
                throw MessageError.malformed(message: message, mission: .orion)
            }
            
            let orionMessage = try jsonDecoder.decode(OrionMessage.self, from: data)
            print("🚀 Orion: \(orionMessage.message)")
        } catch {
            guard let nextHandler else {
                throw MessageError.unknown
            }
            
            try nextHandler.process(message)
        }
    }
}

final class VoyagerMessageHandler: MessageHandler {
    var nextHandler: MessageHandler?
    
    func process(_ message: String) throws {
        let regex = #/^VYYR\s{1,4}(?<id>\d{1})\s{1,4}(?<distance>\d{1,}\.\d{1,3})\s{1,}/#
        let match = try regex.firstMatch(in: message)
        
        if let match {
            print("🛸 La sonda Voyager \(match.id) se encuentra a \(match.distance) millones de kilómetros")
        } else if let nextHandler {
            try nextHandler.process(message)
        } else {
            throw MessageError.unknown
        }
    }
}

///
/// Gestor de la cadena Chain of Responsibility
///


final class MessageManager {
    private var handlers: [MessageHandler]
    
    init() {
        handlers = [
            OrionMessageHandler(),
            VoyagerMessageHandler(),
            PerseveranceMessageHandler()
        ]
        
        buildHandlersChain()
    }
    
    private func buildHandlersChain() {
        for index in 0 ..< handlers.count - 1 {
            handlers[index].nextHandler = handlers[index + 1]
        }
    }
    
    func process(_ message: String) {
        do {
            try self.handlers.first?.process(message)
        } catch MessageError.unknown {
            print("🚨 El mensaje no pertenece a ninguno de los handler registrados")
        } catch let error {
            print("ERROR: \(error.localizedDescription)")
        }
    }
}

///
/// Ejecutar el playground
///

let manager = MessageManager()

for message in messages.split(separator: "\n") {
    manager.process(String(message))
}
