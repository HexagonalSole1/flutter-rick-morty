// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@main
class AppDelegate: FlutterAppDelegate {
    private var securityChannel: FlutterMethodChannel?
    private var overlayView: UIView?
    private var blurEffectView: UIVisualEffectView?
    private var isSecured = false
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Configurar el canal de seguridad
        setupSecurityChannel(controller: controller)
        
        // Configurar notificaciones del ciclo de vida
        setupSecurityNotifications()

        GeneratedPluginRegistrant.register(with: self)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupSecurityChannel(controller: FlutterViewController) {
        securityChannel = FlutterMethodChannel(
            name: "security_channel",
            binaryMessenger: controller.binaryMessenger
        )

        securityChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else {
                result(false)
                return
            }

            switch call.method {
            case "enableScreenSecurity":
                self.enableScreenSecurity(result: result)
            case "disableScreenSecurity":
                self.disableScreenSecurity(result: result)
            case "checkScreenRecording":
                self.checkScreenRecording(result: result)
            case "preventAppSwitcherSnapshot":
                result(true) // Se maneja automáticamente
            case "startScreenRecordingMonitoring":
                self.startScreenRecordingMonitoring(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func enableScreenSecurity(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(false)
                return
            }

            self.addSecureOverlay()
            self.isSecured = true
            print("✅ iOS: Seguridad habilitada")
            result(true)
        }
    }

    private func disableScreenSecurity(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                result(false)
                return
            }

            self.removeSecureOverlay()
            self.isSecured = false
            print("🔓 iOS: Seguridad deshabilitada")
            result(true)
        }
    }

    private func checkScreenRecording(result: @escaping FlutterResult) {
        if #available(iOS 11.0, *) {
            let isRecording = UIScreen.main.isCaptured
            print(isRecording ? "🔴 iOS: Grabación detectada" : "✅ iOS: Sin grabación")
            result(isRecording)
        } else {
            result(false)
        }
    }

    private func startScreenRecordingMonitoring(result: @escaping FlutterResult) {
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleScreenCaptureChange),
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
            print("📱 iOS: Monitoreo de grabación iniciado")
        }
        result(true)
    }

    @available(iOS 11.0, *)
    @objc private func handleScreenCaptureChange() {
        let isRecording = UIScreen.main.isCaptured
        print(isRecording ? "🔴 iOS: Grabación iniciada" : "✅ iOS: Grabación detenida")

        DispatchQueue.main.async { [weak self] in
            self?.securityChannel?.invokeMethod("onScreenRecordingChanged", arguments: isRecording)
        }
    }

    private func addSecureOverlay() {
        guard let window = self.window,
              overlayView == nil else { return }

        // Crear vista de seguridad
        overlayView = UIView(frame: window.bounds)
        overlayView?.backgroundColor = UIColor.black
        overlayView?.alpha = 0.0
        overlayView?.isUserInteractionEnabled = false

        // Agregar ícono de seguridad
        let secureLabel = UILabel()
        secureLabel.text = "🔒"
        secureLabel.font = UIFont.systemFont(ofSize: 80)
        secureLabel.textAlignment = .center
        secureLabel.translatesAutoresizingMaskIntoConstraints = false

        let messageLabel = UILabel()
        messageLabel.text = "Contenido Protegido"
        messageLabel.textColor = UIColor.white
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        overlayView?.addSubview(secureLabel)
        overlayView?.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            secureLabel.centerXAnchor.constraint(equalTo: overlayView!.centerXAnchor),
            secureLabel.centerYAnchor.constraint(equalTo: overlayView!.centerYAnchor, constant: -20),
            messageLabel.centerXAnchor.constraint(equalTo: overlayView!.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: secureLabel.bottomAnchor, constant: 10)
        ])

        window.addSubview(overlayView!)
    }

    private func removeSecureOverlay() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }

    private func setupSecurityNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(securityWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(securityDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func securityWillResignActive() {
        // Mostrar protección cuando la app va a background
        addSecurityBlur()

        if isSecured {
            DispatchQueue.main.async { [weak self] in
                self?.overlayView?.alpha = 1.0
            }
        }
    }

    @objc private func securityDidBecomeActive() {
        // Ocultar protección cuando la app vuelve al foreground
        removeSecurityBlur()

        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.3) {
                self?.overlayView?.alpha = 0.0
            }
        }
    }

    private func addSecurityBlur() {
        guard let window = self.window,
              blurEffectView == nil else { return }

        // Usar efecto compatible con versiones anteriores
        let blurEffect: UIBlurEffect
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemMaterialDark)
        } else {
            blurEffect = UIBlurEffect(style: .dark)
        }

        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView?.frame = window.bounds
        blurEffectView?.alpha = 0.0

        // Agregar contenido al blur
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let lockIcon = UILabel()
        lockIcon.text = "🔒"
        lockIcon.font = UIFont.systemFont(ofSize: 60)
        lockIcon.textAlignment = .center
        lockIcon.translatesAutoresizingMaskIntoConstraints = false

        let appName = UILabel()
        appName.text = "Rick and Morty"
        appName.textColor = UIColor.white
        appName.textAlignment = .center
        appName.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        appName.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(lockIcon)
        containerView.addSubview(appName)
        blurEffectView?.contentView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: blurEffectView!.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: blurEffectView!.centerYAnchor),

            lockIcon.topAnchor.constraint(equalTo: containerView.topAnchor),
            lockIcon.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            appName.topAnchor.constraint(equalTo: lockIcon.bottomAnchor, constant: 16),
            appName.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            appName.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        window.addSubview(blurEffectView!)

        UIView.animate(withDuration: 0.2) {
            self.blurEffectView?.alpha = 1.0
        }
    }

    private func removeSecurityBlur() {
        UIView.animate(withDuration: 0.2, animations: {
            self.blurEffectView?.alpha = 0.0
        }) { _ in
            self.blurEffectView?.removeFromSuperview()
            self.blurEffectView = nil
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}