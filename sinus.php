<?php

    $numberString = '8,9,10,12,13,14,14,15,15,15,14,14,13,12,10,9,8,6,5,3,2,1,1,0,0,0,1,1,2,3,5,6';
    $numbers = explode(',', $numberString);
    $results = [];
    foreach($numbers as $number)
    {
        $results[] = $number + 0xD6 - 0x08;
        $results[] = $number + 0xD6 - 0x08;
    }

    print implode(',', $results)."\n";