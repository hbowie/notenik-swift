Title:  Code Blocks

Seq:    8

Body: 

This is a normal paragraph. 

Following is a block of Swift code: 

    func closeBlocks(from startToClose: Int) {
        var blockToClose = openBlocks.count - 1
        while blockToClose >= startToClose {
            closeBlock(openBlocks.blocks[blockToClose].tag)
            openBlocks.removeLast()
            blockToClose -= 1
        }
    }

And following is a block of HTML code:

	<html>
