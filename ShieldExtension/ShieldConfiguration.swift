// ShieldConfiguration.swift
// SENTINELLE FOCUS — Personnalisation de l'écran de blocage Apple
// Target séparé : "SentinelleShieldExtension"

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Ce fichier doit être dans une target Extension séparée (Shield Configuration Extension)
// Xcode > File > New Target > Shield Configuration Extension

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: UIColor(white: 0.0, alpha: 0.97),
            icon: UIImage(systemName: "lock.fill")?.withTintColor(
                UIColor(white: 0.55, alpha: 1.0),
                renderingMode: .alwaysOriginal
            ),
            title: ShieldConfiguration.Label(
                text: "FOCUS ACTIF",
                color: UIColor(white: 0.88, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Cette application est bloquée pendant votre session.",
                color: UIColor(white: 0.35, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "RETOURNER",
                color: UIColor(white: 0.6, alpha: 1.0)
            ),
            primaryButtonBackgroundColor: UIColor(white: 0.0, alpha: 1.0)
        )
    }

    override func configuration(
        shielding application: Application,
        in webDomain: WebDomain
    ) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(
        shielding webDomain: WebDomain
    ) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: UIColor(white: 0.0, alpha: 0.97),
            icon: UIImage(systemName: "lock.fill")?.withTintColor(
                UIColor(white: 0.55, alpha: 1.0),
                renderingMode: .alwaysOriginal
            ),
            title: ShieldConfiguration.Label(
                text: "FOCUS ACTIF",
                color: UIColor(white: 0.88, alpha: 1.0)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Ce site est bloqué pendant votre session.",
                color: UIColor(white: 0.35, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "RETOURNER",
                color: UIColor(white: 0.6, alpha: 1.0)
            ),
            primaryButtonBackgroundColor: UIColor.black
        )
    }
}
