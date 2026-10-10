// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DocumentVerification {
    struct Document {
        string cid;
        address issuer;
        uint256 timestamp;
        bool exists;
    }

    mapping(bytes32 => Document) private documents;

    event DocumentStored(
        bytes32 indexed hash,
        string cid,
        address indexed issuer
    );

    function storeDocument(bytes32 _hash, string memory _cid)
        public
    {
        require(_hash != bytes32(0), "Hash tidak valid");
        require(bytes(_cid).length > 0,
            "CID tidak boleh kosong");
        require(!documents[_hash].exists,
            "Dokumen sudah terdaftar");

        documents[_hash] = Document({
            cid: _cid,
            issuer: msg.sender,
            timestamp: block.timestamp,
            exists: true
        });

        emit DocumentStored(_hash, _cid, msg.sender);
    }

    function getDocument(bytes32 _hash)
        public
        view
        returns (
            string memory cid,
            address issuer,
            uint256 timestamp
        )
    {
        require(documents[_hash].exists,
            "Dokumen tidak ditemukan");

        Document memory doc = documents[_hash];
        return (doc.cid, doc.issuer, doc.timestamp);
    }

    function verifyDocument(bytes32 _hash)
        public
        view
        returns (bool)
    {
        return documents[_hash].exists;
    }
}
