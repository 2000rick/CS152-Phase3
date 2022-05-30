#include "lib.h"

// Write your class implementation
std::string newtemp() {
    static unsigned int count = 0;
    std::string temp = "__temp__" + std::to_string(count++);
    return temp;
}

std::string newlabel() {
    static unsigned int count = 0;
    std::string label = "__label__" + std::to_string(count++);
    return label;
}

