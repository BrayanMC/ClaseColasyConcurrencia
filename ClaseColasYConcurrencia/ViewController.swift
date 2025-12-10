//
//  ViewController.swift
//  ClaseColasYConcurrencia
//
//  Created by Brayan Munoz Campos on 10/12/25.
//

import UIKit

/// **DispatchQueue - Sistema de Colas de Despacho de GCD (Grand Central Dispatch)**
///
/// DispatchQueue es una cola (queue) que almacena tareas en orden FIFO (First In, First Out).
/// Gestiona cómo se ejecutan esas tareas: de forma serial (una por una) o concurrente (múltiples simultáneas).
/// Para ejecutarlas, usa un pool de threads (grupo de threads reutilizables).
///
/// **Flujo de ejecución:**
/// ```
/// ┌──────────────┐      ┌───────────┐      ┌──────────────┐      ┌──────────────┐      ┌─────┐
/// │  Tu código   │ ───→ │   Cola    │ ───→ │  Scheduler   │ ───→ │ Pool Threads │ ───→ │ CPU │
/// │              │      │   FIFO    │      │  (asigna)    │      │              │      │     │
/// │ .async { }   │      │ [T1,T2,T3]│      │              │      │  Thread 1    │      │     │
/// │              │      │           │      │   Decide     │      │  Thread 2    │      │     │
/// │              │      │           │      │   qué thread │      │  Thread 3    │      │     │
/// └──────────────┘      └───────────┘      └──────────────┘      └──────────────┘      └─────┘
///
/// 1. Envías tarea a la cola
/// 2. Cola almacena en orden FIFO
/// 3. Scheduler toma tarea y busca thread disponible del pool
/// 4. Thread del pool ejecuta la tarea
/// 5. CPU procesa
/// ```
///
/// **Componentes:**
/// - **Cola**: Almacena tareas en orden FIFO
/// - **Scheduler**: Asigna tareas a threads disponibles (automático, no lo controlas)
/// - **Pool de Threads**: Threads reutilizables del sistema
/// - **Serial**: 1 thread ejecuta una por una | **Concurrent**: múltiples threads simultáneamente
///
/// **Tipos de colas:**
/// - `DispatchQueue.main` - Cola serial para UI (thread principal)
/// - `DispatchQueue.global(qos:)` - Colas concurrentes del sistema
/// - Colas personalizadas - Creadas con `DispatchQueue(label:)`
///
/// **Modos de ejecución:**
/// - `.async` - Ejecuta sin bloquear, retorna inmediatamente
/// - `.sync` - Ejecuta y bloquea hasta finalizar
///
/// **Quality of Service (QoS) - Prioridades:**
/// - `.userInteractive` - Máxima prioridad (UI, animaciones)
/// - `.userInitiated` - Alta (usuario esperando resultado)
/// - `.default` - Normal
/// - `.utility` - Baja (descargas largas, procesamiento)
/// - `.background` - Mínima (limpieza, sincronización)
///
/// **Ejemplo básico:**
/// ```swift
/// // Tarea en background
/// DispatchQueue.global(qos: .userInitiated).async {
///     let data = performHeavyTask()
///
///     // Volver a main para actualizar UI
///     DispatchQueue.main.async {
///         self.label.text = data
///     }
/// }
/// ```
class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var processSerialButton: UIButton!
    @IBOutlet weak var processParallelButton: UIButton!
    @IBOutlet weak var syncAsyncButton: UIButton!
    @IBOutlet weak var groupButton: UIButton!
    @IBOutlet weak var serialConcurrentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    // MARK: - 1. async - Background sin bloquear UI
    
    /// **DEMUESTRA:** Tarea pesada en background + actualizar UI
    /// **PATRÓN:** background → main
    @IBAction func downloadImageTapped(_ sender: Any) {
        print("\n🚀 EJEMPLO 1: async - Background sin bloquear UI")
        
        // Actualizar UI (siempre en main)
        DispatchQueue.main.async {
            self.progressLabel.text = "Descargando..."
            self.imageView.image = nil
        }
        
        // Tarea pesada en background (userInitiated = prioridad alta)
        DispatchQueue.global(qos: .userInitiated).async {
            print("⬇️ Descargando...")
            sleep(3)  // Simula descarga
            
            // Volver a main para actualizar UI
            DispatchQueue.main.async {
                self.imageView.image = UIImage(systemName: "photo.fill")
                self.progressLabel.text = "✅ Completado"
                print("✅ Descarga terminada")
            }
        }
    }
    
    // MARK: - 2. Procesamiento SERIAL (sin paralelismo)
    
    /// **DEMUESTRA:** Procesar 1000 números UNO POR UNO (1 core)
    /// **MÉTODO:** For loop tradicional en background
    @IBAction func processSerialTapped(_ sender: Any) {
        print("\n📝 EJEMPLO 2: Procesamiento SERIAL (sin paralelismo)")
        
        DispatchQueue.main.async {
            self.progressLabel.text = "Procesando serial..."
        }
        
        DispatchQueue.global(qos: .utility).async {
            let start = Date()
            var results = Array(repeating: 0, count: 1000)
            
            // ❌ SIN PARALELISMO - For loop normal (usa 1 solo core)
            // Procesa: 0, luego 1, luego 2, luego 3... uno por uno
            for i in 0..<1000 {
                results[i] = self.complexCalculation(i)
            }
            
            let time = Date().timeIntervalSince(start)
            let cores = ProcessInfo.processInfo.activeProcessorCount
            
            DispatchQueue.main.async {
                self.progressLabel.text = "⏱️ Serial: \(String(format: "%.3f", time))s (1 core)"
                print("⏱️ Tiempo serial: \(String(format: "%.3f", time))s")
                print("💻 Cores disponibles: \(cores), pero solo usó 1")
            }
        }
    }
    
    // MARK: - 3. Procesamiento PARALELO (múltiples cores)
    
    /// **DEMUESTRA:** Procesar 1000 números EN PARALELO (múltiples cores)
    /// **MÉTODO:** concurrentPerform aprovecha todos los cores
    @IBAction func processParallelTapped(_ sender: Any) {
        print("\n⚡️ EJEMPLO 3: Procesamiento PARALELO (múltiples cores)")
        
        DispatchQueue.main.async {
            self.progressLabel.text = "Procesando paralelo..."
        }
        
        DispatchQueue.global(qos: .utility).async {
            let start = Date()
            var results = Array(repeating: 0, count: 1000)
            let cores = ProcessInfo.processInfo.activeProcessorCount
            
            // ✅ CON PARALELISMO - concurrentPerform (usa todos los cores)
            // Reparte las 1000 tareas entre los cores disponibles
            // Si tienes 6 cores, ejecuta ~6 tareas simultáneamente
            DispatchQueue.concurrentPerform(iterations: 1000) { i in
                results[i] = self.complexCalculation(i)
            }
            
            let time = Date().timeIntervalSince(start)
            
            DispatchQueue.main.async {
                self.progressLabel.text = "⚡️ Paralelo: \(String(format: "%.3f", time))s (\(cores) cores)"
                print("⏱️ Tiempo paralelo: \(String(format: "%.3f", time))s")
                print("💻 Usó \(cores) cores simultáneamente")
                print("🚀 Aproximadamente \(cores)x más rápido que serial")
            }
        }
    }
    
    // MARK: - 4. sync vs async
    
    /// **DEMUESTRA:** Diferencia entre bloquear (.sync) y no bloquear (.async)
    @IBAction func syncAsyncTapped(_ sender: Any) {
        print("\n📊 EJEMPLO 4: sync vs async")
        
        // SYNC - BLOQUEA
        print("1. Antes de sync")
        DispatchQueue.global().sync {
            sleep(2)
            print("2. Dentro de sync (bloqueó 2s)")
        }
        print("3. Después de sync (esperó)")
        
        print("")
        
        // ASYNC - NO BLOQUEA
        print("4. Antes de async")
        DispatchQueue.global().async {
            sleep(2)
            print("6. Dentro de async")
        }
        print("5. Después de async (no esperó)")
        
        DispatchQueue.main.async {
            self.progressLabel.text = "✅ Ver consola"
        }
    }
    
    // MARK: - 5. DispatchGroup - Coordinar múltiples tareas
    
    /// **DEMUESTRA:** Esperar a que múltiples tareas terminen
    /// **PATRÓN:** enter() → tarea → leave() → notify()
    @IBAction func groupTapped(_ sender: Any) {
        print("\n🔄 EJEMPLO 5: DispatchGroup - Coordinar múltiples tareas")
        
        DispatchQueue.main.async {
            self.progressLabel.text = "Descargando 3 recursos..."
        }
        
        let group = DispatchGroup()
        
        // 3 tareas en paralelo
        group.enter()
        print("📥 Iniciando descarga 1 (3s)...")
        DispatchQueue.global().async {
            sleep(3)
            print("✅ Descarga 1 completada")
            group.leave()
        }
        
        group.enter()
        print("📥 Iniciando descarga 2 (1s)...")
        DispatchQueue.global().async {
            sleep(1)
            print("✅ Descarga 2 completada")
            group.leave()
        }
        
        group.enter()
        print("📥 Iniciando descarga 3 (2s)...")
        DispatchQueue.global().async {
            sleep(2)
            print("✅ Descarga 3 completada")
            group.leave()
        }
        
        // Se ejecuta cuando TODAS terminen (~3s, no 6s)
        group.notify(queue: .main) {
            self.progressLabel.text = "✅ Las 3 descargas listas"
            print("🎉 TODAS las descargas terminaron")
        }
    }
    
    // MARK: - 6. Serial vs Concurrent
    
    /// **DEMUESTRA:** Diferencia entre ejecutar en orden vs paralelo
    @IBAction func serialConcurrentTapped(_ sender: Any) {
        print("\n⚖️ EJEMPLO 6: Serial vs Concurrent")
        
        // SERIAL - Orden garantizado (1→2→3)
        let serial = DispatchQueue(label: "com.example.serial")
        print("📝 Serial Queue:")
        serial.async { print("  1 (serial)") }
        serial.async { print("  2 (serial)") }
        serial.async { print("  3 (serial)") }
        print("   → Salida garantizada: 1, 2, 3")
        
        sleep(4)
        print("\n")
        
        // CONCURRENT - Orden aleatorio (puede ser 2→1→3)
        let concurrent = DispatchQueue(label: "com.example.concurrent", attributes: .concurrent)
        print("🚀 Concurrent Queue:")
        concurrent.async { print("  A (concurrent)") }
        concurrent.async { print("  B (concurrent)") }
        concurrent.async { print("  C (concurrent)") }
        print("   → Salida aleatoria: puede ser B, A, C")
        
        DispatchQueue.main.async {
            self.progressLabel.text = "✅ Ver consola"
        }
    }
    // MARK: - Helper
    
    /// Simula cálculo complejo para demostrar paralelismo
    private func complexCalculation(_ number: Int) -> Int {
        var result = Double(number)
        
        // Operaciones matemáticas pesadas
        for _ in 0..<50000 {
            result = sqrt(result * 2.5)
            result = pow(result, 1.5)
            result = sin(result) * cos(result) * 1000
            result = abs(result)
        }
        
        return Int(result) % 1000
    }
}
