// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./enums/roles.sol";
import "./entities/firm.sol";
import "./entities/verify.sol";
import "./entities/product.sol";
import "./entities/transit.sol";
import "./libraries/helper.sol";


contract ProductTracker {

    event VerifyProduct(
        uint indexed newProductId, 
        uint verifySubProductId, 
        uint32 status, 
        uint date,
        string subProductName,
        string parentProductName,
        string requestor,
        string confirmer,
        uint verifyId);
    event AddProduct(uint indexed uid, string manufacturer, string origin, string productName);                               

    // USER MAPPINGS
    mapping(address => Roles) private userRoles;    // kullanıcı adresi ve eşleşen rolü
    // FIRM MAPPINGS
    mapping(address => Firm) private firmAndOwner;        // firma sahibi ve eşleşen firma bilgileri  
    mapping(address => uint[]) private firmAndProducts;   // firma ve ona ait ürünlerin id leri
    mapping(address => uint[]) private firmAndVerifies;   // firma ve ona ait doğrulamaların id leri
    // PRODUCT MAPPINGS
    mapping(uint => Product) private products;      // ürün id si ve eşleşen ürün bilgileri
    // mapping(uint => Verify[]) private productSubProducts; // ürün id si ve ona eklenen alt ürünün doğrulama bilgileri
    mapping(uint => uint[]) private productVerifies;  // ürün id si ve ona ait doğrulama kaydının id si
    // -----------------
    // VERIFY MAPPING
    mapping(uint => Verify) private verifies;    // doğrulama id si ve eşleşen doğrulama bilgileri


    address immutable public owner; 
    uint private count;
    uint public verifyCount;

    constructor() {
        owner = msg.sender;
        userRoles[owner] = Roles.Owner;
    }

    function createFirmAndOwner(
        address _firmOwner, string calldata _firmName, string calldata _firmLocation, bool _isProducerOrShipper
    ) onlyAuthorized(Roles.Owner) external {
        Roles _role =  _isProducerOrShipper ? Roles.Producer : Roles.Shipper;   // true: producer, false: shipper
        firmAndOwner[_firmOwner] = Firm(_firmName, _firmLocation, _role, _firmOwner);
        userRoles[_firmOwner] = _role;
    }


    function verifySubProduct(uint _verifyId, uint32 _status) 
    isProductOwner(verifies[_verifyId].verifySubProduct)
    external {
        verifies[_verifyId].verifyStatus = _status;
        verifies[_verifyId].verifyDate = block.timestamp;
        verifies[_verifyId].verifyAddress = msg.sender;

        Verify memory verifiedProduct = verifies[_verifyId];

        emit VerifyProduct(
                    verifiedProduct.verifyParentProduct, 
                    verifiedProduct.verifySubProduct, 
                    _status, 
                    verifiedProduct.verifyDate, 
                    products[verifiedProduct.verifySubProduct].productName,
                    products[verifiedProduct.verifyParentProduct].productName, 
                    products[verifiedProduct.verifyParentProduct].manufacturer,
                    products[verifiedProduct.verifySubProduct].manufacturer,
                    _verifyId
                    );

    }


    function addNewProduct (string calldata _productName)
    onlyAuthorized(Roles.Producer)
    external returns(uint) {
        string memory _manufacturer = firmAndOwner[msg.sender].firmName;
        string memory _origin = firmAndOwner[msg.sender].firmLocation;
        uint _uid = Helper.getUniqueId(count++);
        products[_uid] = Product(_uid, _productName, _manufacturer, _origin, _origin, msg.sender);
        firmAndProducts[msg.sender].push(_uid);
        emit AddProduct(_uid, _manufacturer, _origin, _productName);
        return _uid;
    }

    function addSubProduct(uint _newProductId, uint _childProductId) 
    isProductOwner(_newProductId)
    external {
        uint _date = block.timestamp;
        uint _uid = verifyCount++;
        verifies[_uid] = Verify(_uid, _childProductId, uint32(VerifyStatus.Waiting), _date, address(0), _newProductId);
        productVerifies[_newProductId].push(_uid);
        firmAndVerifies[products[_childProductId].manufacturerId].push(_uid);

        emit VerifyProduct(
            _newProductId, 
            _childProductId,  
            uint32(VerifyStatus.Waiting), 
            _date,
            products[_childProductId].productName,
            products[_newProductId].productName,
            products[_newProductId].manufacturer,
            products[_childProductId].manufacturer,
            _uid
            );
    }

    function getProductById(uint _uid) external view returns(Product memory) {
        return products[_uid];
    }

    function getFirmById(address _ownerAddress) external view returns(Firm memory) {
        return firmAndOwner[_ownerAddress];
    }

    function getRole() external view returns(uint32) {
        return uint32(userRoles[msg.sender]);
    }

    function getFirmProducts(address firmOwner) external view returns(Product[] memory) {
        uint[] memory firmProductIdList = firmAndProducts[firmOwner];
        uint length = firmProductIdList.length;
        Product[] memory firmProducts = new Product[](length);
        for(uint i; i<length;) {
            firmProducts[i] = products[firmProductIdList[i]];
            unchecked{i++;}
        }
        return firmProducts;
    }

    function getFirmVerifies(address firmOwner) external view returns(Verify[] memory) {
        uint[] memory firmVerifyIdList = firmAndVerifies[firmOwner];
        uint length = firmVerifyIdList.length;
        Verify[] memory firmVerifies = new Verify[](length);
        for(uint i; i<length;) {
            firmVerifies[i] = verifies[firmVerifyIdList[i]];
            unchecked{i++;}
        }
        return firmVerifies;
    }

    modifier isProductOwner(uint _uid) {
        require(products[_uid].manufacturerId == msg.sender, "You are not product owner");
        _;
    }

    modifier onlyAuthorized(Roles roleType) {
        require(userRoles[msg.sender] == roleType, "Only authorized person can call");
        _;
    }

}
