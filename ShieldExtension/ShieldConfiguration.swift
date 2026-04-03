import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    // Pour les applications individuelles
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createShieldConfig(title: "Sentinelle : App Bloquée")
    }
    
    // Pour les applications au sein d'une catégorie spécifique
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfig(title: "Sentinelle : Catégorie Bloquée")
    }
    
    // Pour les domaines Web
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createShieldConfig(title: "Sentinelle : Site Bloqué")
    }
    
    // Pour les domaines Web au sein d'une catégorie
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return createShieldConfig(title: "Sentinelle : Web Bloqué")
    }

    // Design commun (Noir pur OLED)
    private func createShieldConfig(title: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: .black,
            icon: UIImage(systemName: "lock.shield.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: "Restez concentré sur votre objectif.", color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "OK", color: .black),
            primaryButtonBackgroundColor: .white
        )
    }
}