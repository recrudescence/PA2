# Calvin Wang
# COSI 105B
# Movies-2

# INSPIRED BY:
# http://www.thelearningpoint.net/computer-science/basic-data-structures-in-ruby---binary-search-tre

class TreeNode
    attr_accessor :value, :obj, :left, :right
    
    # each node contains a field for value and obj id; we sort by value
    # objs with more value will be placed on the left, objs with less on the right
    def initialize obj_id, val, left, right
        @value = val
        @obj = obj_id
        @left = left
        @right = right
    end
end

class BinarySearchTree
    attr_accessor :q, :root

    # initialize root node
    def initialize obj_id, value
        @root = TreeNode.new(obj_id, value, nil,nil)  
        @q = Queue.new
    end

    # in order traversal traverses in sorted order, left to right (high to low value)
    # using recursion to dig into leftmost child. returns a queue containing the values.
    def in_order_traversal (node = root)
        if (node == nil) then return q end
        in_order_traversal(node.left)
        q.push("#{node.obj}:\t#{node.value.round(3)}")
        in_order_traversal(node.right)
    end

    def reverse_order_traversal (node = root)
        if (node == nil) then return q end
        in_order_traversal(node.right)
        q.push("#{node.obj}:\t#{node.value.round(3)}")
        in_order_traversal(node.left)
    end

    # insert new obj
    # if obj's val > current node's value, go left
    # if this obj's value is <= the current node's value, go right
    # return if obj already exists in tree
    def insert obj_id, value
        current_node = root
        while nil != current_node
            if (value > current_node.value) && (current_node.left == nil)
                current_node.left = TreeNode.new(obj_id, value, nil, nil)
            # account for obj_id == current_node.obj because of the = part of the <=
            elsif (value <= current_node.value) && (current_node.right == nil) && 
                    (obj_id != current_node.obj)
                current_node.right = TreeNode.new(obj_id, value, nil, nil)
            elsif (value > current_node.value)
                current_node = current_node.left
            elsif (value <= current_node.value) && (obj_id != current_node.obj)
                current_node = current_node.right
            else
                return
            end
        end
    end
end