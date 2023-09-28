#!/bin/bash

# Read the first arg passed to the script
first_arg=$1

HYPER=0
if command -v hyperfine &>/dev/null; then
    HYPER=1
fi

run_go() {
    echo "Running Go" &&
        cd ./go &&
        go build &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 10 -w 3 --show-output "./related"
        else
            command time -f '%es %Mk' ./related
        fi

    check_output "related_posts_go.json"

}

run_go_concurrent() {
    echo "Running Go with concurrency" &&
        cd ./go_con &&
        GOEXPERIMENT=arenas go build &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 10 -w 3 --show-output "./related_concurrent"
        else
            command time -f '%es %Mk' ./related_concurrent
        fi

    check_output "related_posts_go_con.json"
}

run_rust() {
    echo "Running Rust" &&
        cd ./rust &&
        cargo build --release &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 10 -w 3 --show-output "./target/release/rust"
        else
            command time -f '%es %Mk' ./target/release/rust
        fi

    check_output "related_posts_rust.json"

}

run_rust_rayon() {
    echo "Running Rust w/ Rayon" &&
        cd ./rust_rayon &&
        cargo build --release &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 10 -w 3 --show-output "./target/release/rust_rayon"
        else
            command time -f '%es %Mk' ./target/release/rust_rayon
        fi

    check_output "related_posts_rust_rayon.json"

}

run_python_np() {
    echo "Running Python with Numpy" &&
        cd ./python &&
        if [ ! -d "venv" ]; then
            python3 -m venv venv
        fi
    source venv/bin/activate &&
        pip freeze | grep numpy || pip install numpy &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 5 --show-output "python3 ./related_np.py"
        else
            command time -f '%es %Mk' python3 ./related_np.py
        fi
    deactivate &&
        check_output "related_posts_python_np.json"

}

run_python() {
    echo "Running Python" &&
        cd ./python &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 5 --show-output "python3 ./related.py"
        else
            command time -f '%es %Mk' python3 ./related.py
        fi

    check_output "related_posts_python.json"

}

run_crystal() {
    echo "Running Crystal" &&
        cd ./crystal &&
        crystal build --release src/crystal.cr &&
        if [ $HYPER == 1 ]; then
            command hyperfine -r 10 --show-output "./crystal"
        else
            command time -f '%es %Mk' ./crystal
        fi

    check_output "related_posts_cr.json"

}

run_zig() {
    echo "Running Zig" &&
        cd ./zig &&
        zig build-exe -lc -O ReleaseFast main.zig
        if [ $HYPER == 1 ]; then
            command hyperfine -r 10 -w 3 --show-output "./main"
        else
            command time -f '%es %Mk' ./main
        fi

    check_output "related_posts_zig.json"

}

check_output() {
    cd .. &&
        echo "Checking output" &&
        python3 verify.py "$1"
}

if [ "$first_arg" = "go" ]; then

    run_go

elif [ "$first_arg" = "go_con" ]; then

    run_go_concurrent

elif [ "$first_arg" = "rust" ]; then

    run_rust

elif [ "$first_arg" = "rust_ray" ]; then

    run_rust_rayon

elif [ "$first_arg" = "py" ]; then

    run_python

elif [ "$first_arg" = "numpy" ]; then

    run_python_np

elif [ "$first_arg" = "cr" ]; then

    run_crystal

elif [ "$first_arg" = "zig" ]; then
    
    run_zig

elif [ "$first_arg" = "all" ]; then

    echo -e "Running all\n" &&
        (run_go 2>/dev/null || echo "GO DIDN'T FINISH. Run individually to debug the error. ./run.sh go") && echo -e "\n" &&
        (run_go_concurrent 2>/dev/null || echo "GO CONCURRENT DIDN'T FINISH. Run individually to debug the error. ./run.sh go_con") && echo -e "\n" &&
        (run_rust 2>/dev/null || echo "RUST DIDN'T FINISH. Run individually to debug the error. ./run.sh rust") && echo -e "\n" &&
        (run_rust_rayon 2>/dev/null || echo "RUST RAYON DIDN'T FINISH. Run individually to debug the error. ./run.sh rust_ray") && echo -e "\n" &&
        (run_python 2>/dev/null || echo "PYTHON DIDN'T FINISH. Run individually to debug the error. ./run.sh py") && echo -e "\n\n" &&
        (run_python_np 2>/dev/null || echo "PYTHON NUMPY DIDN'T FINISH. Run individually to debug the error. ./run.sh numpy") && echo -e "\n"  &&
        (run_crystal 2>/dev/null || echo "CRYSTAL DIDN'T FINISH. Run individually to debug the error. ./run.sh cr") && echo -e "\n" &&
        (run_zig 2>/dev/null || echo "ZIG DIDN'T FINISH. Run individually to debug the error. ./run.sh zig")
        

elif [ "$first_arg" = "clean" ]; then

    echo "cleaning" &&
        cd go && rm -f related &&
        cd .. &&
        cd go_con && rm -f related_concurrent &&
        cd .. &&
        cd rust && cargo clean &&
        cd .. &&
        cd rust_rayon && cargo clean &&
        cd .. &&
        cd zig && rm -f main main.o &&
        cd ..
        rm -f related_*.json

else
    echo "Valid args: go | go_con | rust | rust_ray | py | numpy | cr | zig | all | clean. Unknown argument: $first_arg"
fi
