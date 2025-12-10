//
//  ViewController.swift
//  ClaseColasYConcurrencia
//
//  Created by Brayan Munoz Campos on 10/12/25.
//

import UIKit

/// **DispatchQueue - Sistema de Colas de Despacho de GCD (Grand Central Dispatch)**
///
/// Gestiona la ejecución de tareas de forma concurrente o serial usando un pool de threads. (Grupo de threads reutilizables)
/// Las colas son estructuras FIFO (First In, First Out) que ejecutan bloques de código.
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
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "Esperando..."
        label.textAlignment = .center
        return label
    }()
    
    private let downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("1. Descargar (async)", for: .normal)
        return button
    }()
    
    private let processSerialButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("2. Procesar Serial", for: .normal)
        return button
    }()
    
    private let processParallelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("3. Procesar Paralelo", for: .normal)
        return button
    }()
    
    private let syncAsyncButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("4. sync vs async", for: .normal)
        return button
    }()
    
    private let groupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("5. DispatchGroup", for: .normal)
        return button
    }()
    
    private let serialConcurrentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("6. Serial vs Concurrent", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        downloadButton.addTarget(self, action: #selector(downloadImageTapped), for: .touchUpInside)
        processSerialButton.addTarget(self, action: #selector(processSerialTapped), for: .touchUpInside)
        processParallelButton.addTarget(self, action: #selector(processParallelTapped), for: .touchUpInside)
        syncAsyncButton.addTarget(self, action: #selector(syncAsyncTapped), for: .touchUpInside)
        groupButton.addTarget(self, action: #selector(groupTapped), for: .touchUpInside)
        serialConcurrentButton.addTarget(self, action: #selector(serialConcurrentTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(imageView)
        view.addSubview(progressLabel)
        view.addSubview(downloadButton)
        view.addSubview(processSerialButton)
        view.addSubview(processParallelButton)
        view.addSubview(syncAsyncButton)
        view.addSubview(groupButton)
        view.addSubview(serialConcurrentButton)
        
        imageView.frame = CGRect(x: 50, y: 100, width: 300, height: 200)
        progressLabel.frame = CGRect(x: 50, y: 320, width: 300, height: 30)
        downloadButton.frame = CGRect(x: 100, y: 370, width: 200, height: 44)
        processSerialButton.frame = CGRect(x: 100, y: 424, width: 200, height: 44)
        processParallelButton.frame = CGRect(x: 100, y: 478, width: 200, height: 44)
        syncAsyncButton.frame = CGRect(x: 100, y: 532, width: 200, height: 44)
        groupButton.frame = CGRect(x: 100, y: 586, width: 200, height: 44)
        serialConcurrentButton.frame = CGRect(x: 100, y: 640, width: 200, height: 44)
    }
    
    // MARK: - 1. async - Background sin bloquear UI
    
    /// **DEMUESTRA:** Tarea pesada en background + actualizar UI
    /// **PATRÓN:** background → main
    @objc private func downloadImageTapped() {
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
    @objc private func processSerialTapped() {
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
    @objc private func processParallelTapped() {
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
    @objc private func syncAsyncTapped() {
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
    @objc private func groupTapped() {
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
    @objc private func serialConcurrentTapped() {
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
