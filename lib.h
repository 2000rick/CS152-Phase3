#ifndef LIB_H
#define LIB_H
#include <string>
#pragma once

// Write your class definition here

std::string newtemp() {
    static unsigned int count = 0;
    std::string temp = "temp_" + std::to_string(count++);
    return temp;
}

std::string newlabel() {
    static unsigned int count = 0;
    std::string label = "label_" + std::to_string(count++);
    return label;
}

#endif
