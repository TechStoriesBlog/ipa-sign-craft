//
//  SigningStep.swift
//  IPASignCraft
//
//  Created by Saurav Nagpal on 23/04/26.
//


enum SigningStep: CaseIterable {
    case idle
    case preparing
    case extracting
    case modifying
    case resolvingIdentity
    case embeddingProfile
    case removeOldSign
    case signingFrameworks
    case signingMainBundle
    case verifying
    case repackaging
    case completed
}


extension SigningStep {
    
    static var workflow: [SigningStep] {
        [
            .preparing,
            .extracting,
            .modifying,
            .resolvingIdentity,
            .embeddingProfile,
            .removeOldSign,
            .signingFrameworks,
            .signingMainBundle,
            .verifying,
            .repackaging,
            .completed
        ]
    }
    
    var nextStep: SigningStep? {
        let flow = SigningStep.workflow
        guard let index = flow.firstIndex(of: self),
              index + 1 < flow.count else { return nil }
        return flow[index + 1]
    }
    
    var nextTitle: String? {
        nextStep?.title
    }
}
