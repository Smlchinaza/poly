// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interface for modules
interface IModule {
    function init(address wallet) external;
}

// Interface for the wallet
interface IWallet {
    function invoke(address _to, uint256 _value, bytes calldata _data) external;
}

/**
 * @title SimpleModularWallet
 * @notice A simple modular wallet for hackathon use, inspired by Argent's BaseWallet.
 * @dev Allows an owner to manage modules and execute transactions via modules.
 */
contract SimpleModularWallet is IWallet {
    address public owner;
    mapping(address => bool) public authorised;
    uint256 public moduleCount;

    event AuthorisedModule(address module, bool value);
    event Invoked(address indexed to, uint256 value, bytes data);
    event Received(uint256 value, address sender);

    modifier onlyOwner() {
        require(msg.sender == owner, "SW: caller is not owner");
        _;
    }

    modifier moduleOnly() {
        require(authorised[msg.sender], "SW: caller is not authorised module");
        _;
    }

    // Initialize the wallet with an owner and a module
    function init(address _owner, address _module) external {
        require(owner == address(0) && moduleCount == 0, "SW: wallet already initialised");
        require(_module != address(0), "SW: module cannot be zero address");
        owner = _owner;
        authorised[_module] = true;
        moduleCount = 1;
        IModule(_module).init(address(this));
        emit AuthorisedModule(_module, true);
    }

    // Authorise or deauthorise a module
    function authoriseModule(address _module, bool _value) external onlyOwner {
        require(_module != address(0), "SW: module cannot be zero address");
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value) {
                moduleCount += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this));
            } else {
                moduleCount -= 1;
                require(moduleCount > 0, "SW: cannot remove last module");
                delete authorised[_module];
            }
        }
    }

    // Execute transactions via modules
    function invoke(address _to, uint256 _value, bytes calldata _data) external override moduleOnly {
        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "SW: call failed");
        emit Invoked(_to, _value, _data);
    }

    // Receive ETH
    receive() external payable {
        emit Received(msg.value, msg.sender);
    }
}