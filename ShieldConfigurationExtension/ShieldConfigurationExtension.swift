//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by Paul Ahlstrom on 9/22/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Custom shield configuration for blocked apps
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.95),
            icon: UIImage(systemName: "tree"),
            title: ShieldConfiguration.Label(
                text: "App Restricted",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Earn more screen time by completing tasks",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Envive",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.541, green: 0.416, blue: 0.969, alpha: 1.0), // #8A6AF7
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go to Home Screen",
                color: UIColor.systemBlue
            )
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        // Custom shield configuration for blocked app categories
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.95),
            icon: UIImage(systemName: "tree"),
            title: ShieldConfiguration.Label(
                text: "Category Restricted",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Earn more screen time by completing tasks",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Envive",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.541, green: 0.416, blue: 0.969, alpha: 1.0), // #8A6AF7
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go to Home Screen",
                color: UIColor.systemBlue
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Custom shield configuration for blocked web domains
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.95),
            icon: UIImage(systemName: "tree"),
            title: ShieldConfiguration.Label(
                text: "Website Restricted",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Earn more screen time by completing tasks",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Envive",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.541, green: 0.416, blue: 0.969, alpha: 1.0), // #8A6AF7
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go to Home Screen",
                color: UIColor.systemBlue
            )
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Custom shield configuration for web domains in categories
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor.systemBackground.withAlphaComponent(0.95),
            icon: UIImage(systemName: "tree"),
            title: ShieldConfiguration.Label(
                text: "Website Category Restricted",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Earn more screen time by completing tasks",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Envive",
                color: UIColor.white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.541, green: 0.416, blue: 0.969, alpha: 1.0), // #8A6AF7
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go to Home Screen",
                color: UIColor.systemBlue
            )
        )
    }
}
