// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface ERC721Interface {
    function approve(address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC3525Interface {
    function approve(uint256 tokenId, address to, uint256 allowance) external payable;
    function transferFrom(uint256 fromTokenId, uint256 toTokenId, uint256 value) external payable;
    function transferFrom(uint256 fromTokenId, address to, uint256 value) external payable returns (uint256); 
}

library ERC3525TransferHelper {
    function doApproveId(address underlying, address to, uint256 tokenId) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.approve(to, tokenId);
    }

    function doApproveValue(address underlying, uint256 tokenId, address to, uint256 allowance) internal {
        ERC3525Interface token = ERC3525Interface(underlying);
        token.approve(tokenId, to, allowance);
    }

    function doTransferIn(address underlying, address from, uint256 tokenId) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(from, address(this), tokenId);
    }
    
    function doSafeTransferIn(address underlying, address from, uint256 tokenId) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.safeTransferFrom(from, address(this), tokenId);
    }

    function doSafeTransferOut(address underlying, address to, uint256 tokenId) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.safeTransferFrom(address(this), to, tokenId);
    }

    function doTransferOut(address underlying, address to, uint256 tokenId) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(address(this), to, tokenId);
    }

    function doTransferIn(address underlying, uint256 fromTokenId, uint256 value) internal returns (uint256 newTokenId) {
        ERC3525Interface token = ERC3525Interface(underlying);
        return token.transferFrom(fromTokenId, address(this), value);
    }

    function doTransferOut(address underlying, uint256 fromTokenId, address to, uint256 value) internal returns (uint256 newTokenId) {
        ERC3525Interface token = ERC3525Interface(underlying);
        newTokenId = token.transferFrom(fromTokenId, to, value);
    }

    function doTransfer(address underlying, address from, address to, uint256 tokenId) internal {
        ERC721Interface token = ERC721Interface(underlying);
        token.transferFrom(from, to, tokenId);
    }

    function doTransfer(address underlying, uint256 fromTokenId, uint256 toTokenId, uint256 value) internal {
        ERC3525Interface token = ERC3525Interface(underlying);
        token.transferFrom(fromTokenId, toTokenId, value);
    }

}
