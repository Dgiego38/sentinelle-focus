import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // Configuration pour les Applications
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShieldConfig(title: "FOCUS ACTIF")
    }

    // Configuration pour les Catégories (ex: Réseaux Sociaux)
    override func configuration(shielding category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfig(title: "CATÉGORIE BLOQUÉE")
    }

    // Configuration pour les Domaines Web
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createShieldConfig(title: "SITE BLOQUÉ")
    }

    // Fonction d'aide pour éviter la répétition
    private func createShieldConfig(title: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: UIColor(white: 0.0, alpha: 0.95),
            icon: UIImage(systemName: "lock.fill")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: "Sentinelle Focus protège votre attention.", color: .gray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "RETOURNER", color: .white),
            primaryButtonBackgroundColor: UIColor(white: 0.1, alpha: 1.0)
        )
    }
}