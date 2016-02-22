import UIKit

class PlansAnimatedBox: UIView {
    let freeView = UIImageView(image: UIImage(named: "free")!)
    let premiumView = UIImageView(image: UIImage(named: "premium")!)
    let businessView = UIImageView(image: UIImage(named: "business")!)

    convenience init() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        self.init(frame: frame)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 233/255, green: 239/255, blue: 243/255, alpha: 1)
        clipsToBounds = true
        addSubview(freeView)
        addSubview(premiumView)
        addSubview(businessView)
        let targetY: CGFloat = 10.0
        let offsetY: CGFloat = 42.0
        freeView.center = CGPointApplyAffineTransform(center, CGAffineTransformMakeTranslation(-30, targetY))
        premiumView.center = CGPointApplyAffineTransform(center, CGAffineTransformMakeTranslation(0, targetY))
        businessView.center = CGPointApplyAffineTransform(center, CGAffineTransformMakeTranslation(30, targetY))

        freeView.transform = CGAffineTransformMakeTranslation(0, offsetY)
        premiumView.transform = CGAffineTransformMakeTranslation(0, offsetY)
        businessView.transform = CGAffineTransformMakeTranslation(0, offsetY)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animate() {
        UIView.animateWithDuration(
            1.4,
            delay: 0.1,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.1,
            options: .CurveEaseOut,
            animations: { [unowned freeView] in
                freeView.transform = CGAffineTransformIdentity
            },
            completion: nil)

        UIView.animateWithDuration(
            1,
            delay: 0.0,
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.01,
            options: .CurveEaseOut,
            animations: { [unowned premiumView] in
                premiumView.transform = CGAffineTransformIdentity
            },
            completion: nil)

        UIView.animateWithDuration(
            1.2,
            delay: 0.2,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.1,
            options: .CurveEaseOut,
            animations: { [unowned businessView] in
                businessView.transform = CGAffineTransformIdentity
            },
            completion: nil)
    }
}
