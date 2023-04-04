import Foundation
import VTComponents



//datamanager contract
public protocol TrackClientServiceDataContract {
   func trackClientService(userId: Int, success: @escaping ([Service]) -> Void, failure: @escaping (String) -> Void)
}

//database contract
public protocol TrackClientServiceDatabaseContract {
    func trackClientService(userId: Int, success: @escaping ([Service]) -> Void, failure: @escaping (String) -> Void)
}


//datamanager

public class TrackClientServiceDataManager {
    public var databaseService: TrackClientServiceDatabaseContract

    public init(databaseService: TrackClientServiceDatabaseContract) {
        self.databaseService = databaseService
    }

    private func success(message: [Service], callback: ([Service]) -> Void) {
        callback(message)
    }

    private func failure(message: String, callback: (String) -> Void) {
        if message == "No avaialable service is found " {
            let error = "Sevice with this service id Doesn't exist"
            callback(error)
        }
    }
}

extension TrackClientServiceDataManager: TrackClientServiceDataContract {
    public func trackClientService(userId: Int, success: @escaping ([Service]) -> Void, failure: @escaping (String) -> Void) {
        databaseService.trackClientService(userId: userId, success: {
            [weak self] message in
            self?.success(message: message, callback: success)
        }, failure: {
            [weak self] message in
            self?.failure(message: message, callback: failure)
        })
        
    }
    
}






// use case


public final class TrackClientServiceRequest: Request {
    public var userId: Int
   
    public init(userId: Int) {
        self.userId = userId
        
    }
}

public final class TrackClientServiceResponse: ZResponse {
    public var response: [Service]
    public init(response: [Service]) {
        self.response = response
    }
}

public final class TrackClientServiceError: ZError {
    public var error: String
    init(error: String) {
        self.error = error
        super.init(status: .irresponsiveDatabase)
    }
}

public final class TrackClientService: ZUsecase<TrackClientServiceRequest, TrackClientServiceResponse, TrackClientServiceError> {
    var dataManager: TrackClientServiceDataContract

    public init(dataManager: TrackClientServiceDataContract) {
        self.dataManager = dataManager
    }

    override public func run(request: TrackClientServiceRequest, success: @escaping (TrackClientServiceResponse) -> Void, failure: @escaping (TrackClientServiceError) -> Void) {
        dataManager.trackServiceClient(userId: request.userId, success: { [weak self] message in
            self?.success(message: message, callback: success)
        }, failure: { [weak self] error in
            self?.failure(error: TrackClientServiceError(error: error), callback: failure)
        })
    }

    private func success(message: [Service], callback: @escaping (TrackClientServiceResponse) -> Void) {
        let response = TrackClientServiceResponse(response: message)
        invokeSuccess(callback: callback, response: response)
    }

    private func failure(error: TrackClientServiceError, callback: @escaping (TrackClientServiceError) -> Void) {
        invokeFailure(callback: callback, failure: error)
    }
}

//view

class TrackClientServiceView: NSView {
    
    public var userId: Int
    
    var presenter: TrackClientServicePresenter
    
    init(  userId: Int, presenter: TrackClientServicePresenter) {
        
        self.userId = userId
        
        self.presenter = presenter
        super.init(frame: NSZeroRect)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToSuperview() {
        if superview != nil {
            presenter.viewLoaded(userId: userId )
        }
    }
}

extension TrackClientServiceView: TrackClientServiceViewContract {
    func load(message: String) {
        print(message)
    }
    
    func failed(error: String) {
        print(error)
    }
}

//presenter

class TrackClientServicePresenter {
    weak var view: TrackClientServiceViewContract?
    var trackClientService: TrackClientService
    weak var router: TrackClientServiceRouterContract?

    init(trackClientService: TrackClientService) {
        self.trackClientService = trackClientService
    }
}

extension TrackClientServicePresenter: TrackClientServicePresenterContract {
    func viewLoaded(userId: Int) {
        let request = TrackClientServiceRequest(userId: userId)
        trackClientService.execute(request: request, onSuccess: { [weak self] response in
            self?.result(message: response.response)
        }, onFailure: { [weak self] loginError in
            self?.failed(loginError: loginError.error)
        })
    }
}

extension TrackClientServicePresenter {
    func result(message: [Service]) {
        for user in message{
            
            view?.load(message: user.userName)
            view?.load(message: user.password)
            view?.load(message: user.email)
            view?.load(message: user.mobileNumber.description)
        }
    }

    func failed(loginError: String) {
        view?.load(message: loginError)
    }
}
//presentation contract


protocol TrackClientServiceViewContract: AnyObject {
    func load(message: String)
}

protocol TrackClientServicePresenterContract {
    func viewLoaded(userId: Int)
}

protocol TrackClientServiceRouterContract: AnyObject {
    func selected(message: String)
}